# SENZHUB System Architecture

## High-Level Overview
SENZHUB uses a hybrid IoT architecture, prioritizing local hardware autonomy for safety-critical operations while utilizing a cloud backend (Supabase) for telemetry, organizational management, and remote user control.

## Components

### 1. Hardware Layer (ESP32 Node)
- **Local Priority Engine:** Continuously reads the MQ-6 sensor. If raw sensor readings exceed safety thresholds, it triggers a hardware relay to close the valve instantly, ignoring any conflicting network commands.
- **Communication:** Periodically calls the `device-sync` Edge Function to push telemetry (raw sensor readings, battery, status) and pull pending commands.

### 2. Cloud Layer (Supabase)
- **PostgreSQL Database:** Stores users, devices, organizations, and time-series telemetry. Handles complex security via Row Level Security (RLS) and stored procedures (RPCs).
- **Edge Functions (Deno):**
  - Act as the secure bridge between the mobile app, the database, and the IoT hardware.
  - Run with `service-role` privileges, allowing them to access highly restricted tables (like `device_secrets` or `user_security`) that users and devices cannot access directly.

### 3. Client Layer (Flutter Application)
- **Cross-Platform App:** Authenticates users via Supabase Auth.
- **Real-time UI:** Subscribes to database changes to show live gas-level telemetry and device status.
- **Secure Control:** Dispatches manual valve commands to the `send-valve-command` Edge Function, securely providing the required PIN and OTP for verification.

## Interaction Flow (Valve Command)
1. User requests a valve OPEN via the Flutter App.
2. App prompts for SENZHUB PIN and OTP.
3. App POSTs to `/functions/v1/send-valve-command` with PIN and OTP.
4. Edge Function verifies PIN and OTP via secure database RPCs.
5. If valid, the command is written to the `device_commands` table with `status = PENDING`.
6. ESP32 polls `/functions/v1/device-sync`.
7. `device-sync` authenticates the device, reads `PENDING` commands, and returns them to the device.
8. ESP32 actuates the physical relay and sends an update (e.g., `EXECUTED`) on its next sync.

## State Management
To resolve conflicts between local safety and remote commands, the device maintains absolute authority over its physical state. The cloud represents the "requested" state, but the `device-sync` payload dictates the "actual" state.
