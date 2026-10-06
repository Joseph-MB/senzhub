# SENZHUB API Documentation

## Overview
The mobile app and IoT devices communicate with the backend primarily through Supabase Edge Functions. Direct database modifications for sensitive actions are blocked by Row Level Security.

---

## `POST /functions/v1/send-valve-command`
Used by the Flutter application to queue a command for a specific device.

**Headers:**
- `Authorization: Bearer <USER_JWT>`
- `Content-Type: application/json`

**Body:**
```json
{
  "device_id": "uuid",
  "action": "OPEN" | "CLOSE",
  "reason": "string",
  "pin": "string (4-digit)",
  "otp": "string" (Required if action is OPEN)
}
```

**Responses:**
- `200 OK`: Command queued successfully.
- `400 Bad Request`: Missing fields or invalid action.
- `403 Forbidden`: Invalid PIN, invalid OTP, or insufficient organizational privileges.
- `409 Conflict`: A command is already pending for this device.

---

## `POST /functions/v1/device-sync`
Used by the ESP32 hardware to report telemetry and fetch pending commands.

**Headers:**
- `Content-Type: application/json`

**Body:**
```json
{
  "device_id": "uuid",
  "secret": "string",
  "telemetry": {
    "gas_status": "SAFE" | "WARNING" | "DANGER",
    "valve_status": "OPEN" | "CLOSED"
  },
  "command_updates": [
    {
      "id": "uuid",
      "status": "EXECUTED" | "FAILED"
    }
  ]
}
```

**Responses:**
- `200 OK`: Returns a list of pending commands.
```json
{
  "pending_commands": [
    {
      "id": "uuid",
      "command": "OPEN" | "CLOSE",
      "payload": { "reason": "string" },
      "expires_at": "timestamp"
    }
  ],
  "server_time": "timestamp"
}
```
- `401 Unauthorized`: Invalid `device_id` or `secret`.
