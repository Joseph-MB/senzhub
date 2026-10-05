import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
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

    // Decode JWT payload to check 'amr' claim for 'recovery'
    const tokenParts = token.split('.');
    if (tokenParts.length !== 3) {
      return new Response(JSON.stringify({ error: 'Invalid JWT structure' }), { status: 401, headers: corsHeaders });
    }
    
    let payload;
    try {
      payload = JSON.parse(atob(tokenParts[1]));
    } catch (e) {
      return new Response(JSON.stringify({ error: 'Failed to decode JWT' }), { status: 401, headers: corsHeaders });
    }

    // Inspect the Authentication Methods Reference (amr)
    // A password recovery session securely logs the user in with a 'recovery' method.
    // By checking this, we ensure the user actually proved control of their email just now.
    const amr = payload.amr || [];
    const isRecoverySession = amr.some((m: any) => m.method === 'recovery');

    if (!isRecoverySession) {
      return new Response(JSON.stringify({ 
        error: 'Unauthorized. PIN reset requires a secure recovery session (e.g., clicking a password reset link).' 
      }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const adminClient = createClient(supabaseUrl, supabaseServiceKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const { data: { user }, error: userError } = await adminClient.auth.getUser(token);

    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Invalid token' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const body = await req.json().catch(() => ({}));
    const newPin = body.pin || body.new_pin;

    if (!newPin || typeof newPin !== 'string' || newPin.length !== 4 || !/^\d{4}$/.test(newPin)) {
      return new Response(JSON.stringify({ error: 'Invalid PIN. Must be exactly 4 digits.' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { error: rpcError } = await adminClient.rpc('update_user_pin', {
      p_user_id: user.id,
      p_pin: newPin,
    });

    if (rpcError) {
      console.error('Database error setting new pin:', rpcError);
      return new Response(JSON.stringify({ error: 'Failed to reset PIN' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    return new Response(JSON.stringify({ success: true, message: 'Valve PIN reset successfully' }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (err: any) {
    console.error('Edge Function error in reset-valve-pin:', err);
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
