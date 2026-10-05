import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // 1. Get the auth token from the request
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing Authorization header' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const token = authHeader.replace('Bearer ', '');

    // 2. Initialize Supabase Admin client
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error('Server misconfiguration: missing Supabase URL or Service Key');
    }

    const adminClient = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    // 3. Validate caller token and get User ID
    const { data: { user }, error: userError } = await adminClient.auth.getUser(token);

    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Invalid or expired authentication token' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const userId = user.id;

    // 4. Parse payload
    const body = await req.json().catch(() => ({}));
    const deviceId = body.device_id || body.deviceId;
    const rawAction = (body.action || body.command || '').toString().toUpperCase();
    const reason = (body.reason || 'Manual user request').toString().trim();

    if (!deviceId) {
      return new Response(JSON.stringify({ error: 'Missing required field: device_id' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (rawAction !== 'OPEN' && rawAction !== 'CLOSE') {
      return new Response(JSON.stringify({ error: 'Invalid valve action. Allowed actions are OPEN or CLOSE.' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // 5. Verify target device exists
    const { data: device, error: deviceError } = await adminClient
      .from('devices')
      .select('id, organization_id, device_name, serial_number, valve_status')
      .eq('id', deviceId)
      .maybeSingle();

    if (deviceError || !device) {
      return new Response(JSON.stringify({ error: 'Target device not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // 6. Verify user belongs to the device organization and check authorization role
    const { data: orgUser, error: orgUserError } = await adminClient
      .from('organization_users')
      .select('role')
      .eq('organization_id', device.organization_id)
      .eq('user_id', userId)
      .maybeSingle();

    if (orgUserError || !orgUser) {
      return new Response(JSON.stringify({ error: 'Unauthorized: User does not belong to the device organization' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const role = orgUser.role;
    if (role === 'VIEWER') {
      return new Response(JSON.stringify({ error: 'Forbidden: VIEWERS are not authorized to perform valve operations' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // 6.5 Verify Security Requirements (PIN and OTP)
    const pin = (body.pin || '').toString();
    const otp = (body.otp || '').toString();

    if (!pin) {
      return new Response(JSON.stringify({ error: 'Missing PIN. Valve operations require a secure PIN.' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Verify PIN via secure RPC
    const { data: isPinValid, error: pinError } = await adminClient.rpc('verify_user_pin', { 
      p_user_id: userId, 
      p_pin: pin 
    });

    if (pinError || !isPinValid) {
      return new Response(JSON.stringify({ error: 'Invalid PIN' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (rawAction === 'OPEN') {
      if (!otp) {
        return new Response(JSON.stringify({ error: 'Missing OTP. OPEN operations require a short-lived OTP.' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      // Verify and consume OTP via secure RPC
      const { data: isOtpValid, error: otpError } = await adminClient.rpc('verify_and_consume_otp', {
        p_user_id: userId,
        p_device_id: deviceId,
        p_action: rawAction,
        p_otp: otp
      });

      if (otpError || !isOtpValid) {
        return new Response(JSON.stringify({ error: 'Invalid, expired, or fully consumed OTP' }), {
          status: 403,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }
    }

    // 7. Check for duplicate/pending command in progress for this device
    const { data: pendingCommands } = await adminClient
      .from('device_commands')
      .select('id, status, requested_at')
      .eq('device_id', deviceId)
      .in('status', ['PENDING', 'SENT'])
      .order('requested_at', { ascending: false })
      .limit(1);

    if (pendingCommands && pendingCommands.length > 0) {
      const activeCmd = pendingCommands[0];
      const requestedTime = activeCmd.requested_at ? new Date(activeCmd.requested_at).getTime() : 0;
      const isRecent = (Date.now() - requestedTime) < 30000; // 30 seconds active window

      if (isRecent) {
        return new Response(JSON.stringify({
          error: 'A valve command is already in progress for this device. Please wait for the current command to complete.',
          command_id: activeCmd.id,
          status: activeCmd.status,
        }), {
          status: 409,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }
    }

    // 8. Insert command record into device_commands
    const nowIso = new Date().toISOString();
    const expiresIso = new Date(Date.now() + 30000).toISOString(); // 30s timeout

    const { data: commandRecord, error: insertCmdError } = await adminClient
      .from('device_commands')
      .insert({
        device_id: deviceId,
        command: rawAction,
        payload: { reason },
        status: 'PENDING',
        requested_by: userId,
        requested_at: nowIso,
        expires_at: expiresIso,
      })
      .select('id, status, requested_at')
      .single();

    if (insertCmdError || !commandRecord) {
      console.error('Failed to insert device command:', insertCmdError);
      return new Response(JSON.stringify({ error: 'Database error: Failed to create valve command' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // 9. Insert audit log into valve_events
    const { error: insertEventError } = await adminClient
      .from('valve_events')
      .insert({
        device_id: deviceId,
        actor_id: userId,
        action: rawAction,
        reason: reason,
        created_at: nowIso,
      });

    if (insertEventError) {
      console.warn('Non-fatal warning: failed to insert valve_events record:', insertEventError);
    }

    // 10. Return structured response (dispatched, NOT claimed as physically moved)
    return new Response(JSON.stringify({
      success: true,
      command_id: commandRecord.id,
      status: commandRecord.status,
      message: 'Valve command dispatched successfully. Awaiting physical execution by device hardware.',
      device_id: deviceId,
      action: rawAction,
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (err: any) {
    console.error('Edge Function error in send-valve-command:', err);
    return new Response(JSON.stringify({ error: 'Internal server error processing valve command' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
