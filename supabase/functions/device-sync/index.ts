import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error("Missing Supabase environment variables");
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const { device_id, secret, telemetry, command_updates } = await req.json();

    if (!device_id || !secret) {
      return new Response(JSON.stringify({ error: "Missing device_id or secret" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 1. Authenticate the device
    const { data: secretData, error: secretError } = await supabase
      .from("device_secrets")
      .select("secret")
      .eq("device_id", device_id)
      .single();

    if (secretError || !secretData || secretData.secret !== secret) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 2. Process Telemetry
    if (telemetry) {
      const { error: telemetryError } = await supabase
        .from("devices")
        .update({
          gas_status: telemetry.gas_status,
          valve_status: telemetry.valve_status,
          device_status: "ONLINE",
          last_communication_at: new Date().toISOString(),
        })
        .eq("id", device_id);

      if (telemetryError) {
        console.error("Telemetry error:", telemetryError);
      }
    }

    // 3. Process Command Updates (SENT, EXECUTED, FAILED)
    if (command_updates && Array.isArray(command_updates)) {
      for (const update of command_updates) {
        if (!update.id || !update.status) continue;
        
        const updatePayload: any = { status: update.status };
        if (update.status === "EXECUTED" || update.status === "FAILED" || update.status === "TIMED_OUT") {
          updatePayload.executed_at = new Date().toISOString();
        }

        await supabase
          .from("device_commands")
          .update(updatePayload)
          .eq("id", update.id)
          .eq("device_id", device_id);
      }
    }

    // 4. Fetch Pending Commands & Handle Expiration
    const { data: fetchedCommands, error: fetchError } = await supabase
      .from("device_commands")
      .select("id, command, payload, expires_at")
      .eq("device_id", device_id)
      .eq("status", "PENDING")
      .order("requested_at", { ascending: true });

    if (fetchError) {
      throw fetchError;
    }

    const pendingCommands = [];
    const now = new Date();

    if (fetchedCommands) {
      for (const cmd of fetchedCommands) {
        if (cmd.expires_at && new Date(cmd.expires_at) < now) {
          // Command is expired. Mark it as TIMED_OUT on the server side.
          await supabase
            .from("device_commands")
            .update({ status: "TIMED_OUT", executed_at: now.toISOString() })
            .eq("id", cmd.id);
        } else {
          // Valid command
          pendingCommands.push(cmd);
        }
      }
    }

    return new Response(JSON.stringify({ 
      pending_commands: pendingCommands,
      server_time: now.toISOString()
    }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error: any) {
    console.error("Device Sync Error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
