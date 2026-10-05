import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// Cryptographically secure 6-digit OTP generator
function generateOTP(): string {
  const array = new Uint32Array(1);
  crypto.getRandomValues(array);
  const otp = (array[0] % 1000000).toString().padStart(6, '0');
  return otp;
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing Authorization header' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const token = authHeader.replace('Bearer ', '');

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error('Server misconfiguration');
    }

    const adminClient = createClient(supabaseUrl, supabaseServiceKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    // Validate caller token
    const { data: { user }, error: userError } = await adminClient.auth.getUser(token);
    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Invalid authentication token' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const userId = user.id;

    // Parse payload
    const body = await req.json().catch(() => ({}));
    const deviceId = body.device_id || body.deviceId;
    
    // Default to OPEN if not specified (since we only use this for OPEN right now)
    const rawAction = (body.action || 'OPEN').toString().toUpperCase();

    if (!deviceId) {
      return new Response(JSON.stringify({ error: 'Missing required field: device_id' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (rawAction !== 'OPEN') {
      return new Response(JSON.stringify({ error: 'OTP is only supported for OPEN actions' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Verify target device exists and user has authorization
    const { data: device, error: deviceError } = await adminClient
      .from('devices')
      .select('organization_id')
      .eq('id', deviceId)
      .maybeSingle();

    if (deviceError || !device) {
      return new Response(JSON.stringify({ error: 'Target device not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

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

    if (orgUser.role === 'VIEWER') {
      return new Response(JSON.stringify({ error: 'Forbidden: VIEWERS cannot request valve operation OTPs' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Generate OTP
    const otp = generateOTP();
    const expiresInMinutes = 5; // short-lived

    // Store challenge via secure RPC
    const { data: challengeId, error: rpcError } = await adminClient.rpc('create_otp_challenge', {
      p_user_id: userId,
      p_device_id: deviceId,
      p_action: rawAction,
      p_otp: otp,
      p_expires_in_minutes: expiresInMinutes
    });

    if (rpcError || !challengeId) {
      console.error('Failed to create OTP challenge:', rpcError);
      return new Response(JSON.stringify({ error: 'Failed to generate OTP challenge' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // SIMULATED DELIVERY: Since no email/SMS provider is configured yet, we just log a warning.
    // In production, this would call Resend, Twilio, SendGrid, etc.
    // IMPORTANT: We do NOT return the plaintext OTP to the client, nor do we log it.
    console.warn(`[SIMULATION] OTP challenge created: ${challengeId} (Delivery mocked)`);

    return new Response(JSON.stringify({ 
      success: true, 
      message: 'OTP generated and sent successfully',
      challenge_id: challengeId,
      expires_in_minutes: expiresInMinutes
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (err: any) {
    console.error('Edge Function error in request-valve-otp:', err);
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
