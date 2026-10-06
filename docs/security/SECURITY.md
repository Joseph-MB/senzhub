# SENZHUB Security Architecture

## Database Security (Row Level Security)
All data access from the Flutter application is strictly scoped via Supabase Row Level Security (RLS).
- Verified RLS is configured on: `profiles`, `organizations`, `organization_users`, `locations`, `devices`, `device_readings`, `alerts`, `valve_events`, and `diagnostics`.
- A user can only read devices, telemetry, and alerts belonging to an `organization` they are a member of.
- The `profiles` and `organizations` tables enforce multi-tenancy.

## Valve Security Model
Controlling an LPG valve remotely presents significant physical security risks. SENZHUB implements a defense-in-depth approach.

### 1. Isolated Security Tables
PINs and OTPs are not stored on the `users` or `profiles` tables. They are isolated in protected security tables:
- `user_security`
- `otp_challenges`

These tables have RLS enabled with **no policies granting access to authenticated users**. They are entirely invisible to the public API.

### 2. Service-Role Isolation
Only Edge Functions (using the backend `service-role` key) or secure RPCs (using `SECURITY DEFINER`) can interact with the security tables.

### 3. Cryptographic Hashing
- **PINs:** Server-side validation via `pgcrypto` (`crypt(pin, gen_salt('bf'))`).
- **OTPs:** Hashed upon generation.
Raw PINs/OTPs are never stored, and there is no plaintext PIN/OTP persistence. The client never receives a hash to crack.

### 4. Command Lifecycle
- **CLOSE Command:** Requires the user's 4-digit PIN.
- **OPEN Command:** Requires the user's 4-digit PIN + a valid OTP challenge response.
- **Timeouts:** Commands expire after 30 seconds if the device does not fetch them, preventing stale commands from opening a valve unexpectedly hours later.
- **Rate Limiting / Attempts:** OTP challenges fail permanently after 3 incorrect attempts.

## Device Authentication
Devices do not use standard JWT user authentication. Instead, they authenticate to the `device-sync` Edge Function using a cryptographic `secret` provisioned during manufacturing, stored in the isolated `device_secrets` table.

## Secrets Management
- No Twilio keys, Supabase Service Role keys, or Database URIs are exposed in the Flutter frontend or the hardware firmware.
- Developers must use `.env` files (refer to `.env.example`).
