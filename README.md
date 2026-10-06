# SENZHUB - Smart LPG Gas Safety and Monitoring System

## Project Overview
SENZHUB is an IoT-based LPG safety and monitoring prototype designed to prevent gas-related accidents. It provides real-time gas sensor readings, local automated safety responses, and remote management through a secure mobile application.

## Problem Statement
LPG leakage is a significant domestic and commercial hazard. Traditional setups suffer from delayed detection and rely entirely on manual valve intervention. There is a critical need for a system that provides both a local automatic safety response (closing the valve upon leak detection) and remote monitoring/control capabilities to keep users informed and empowered.

## Solution
SENZHUB solves this by integrating a local gas detection circuit (ESP32 + MQ-6 sensor) directly with an electronic shut-off valve. When dangerous gas levels are detected, the system locally and autonomously shuts off the gas supply, independent of internet connectivity. Simultaneously, it syncs state to a Supabase backend, alerting the user via a Flutter-based mobile application.

## Key Features
- **Real-Time Telemetry:** Continuous monitoring of gas-level telemetry and device status.
- **Autonomous Local Safety:** Hardware-level automatic valve shut-off when raw sensor readings exceed danger thresholds.
- **Secure Remote Control:** Remote valve OPEN/CLOSE commands via the mobile app.
- **Strict Valve Security:** PIN-protected CLOSE and PIN + OTP-protected OPEN commands to prevent accidental or malicious operation.
- **Organizational Management:** Multi-tenant support with role-based access control (Owner, Admin, Operator, Viewer).

## System Architecture
The system consists of interconnected hardware and software layers:
- **ESP32:** The core microcontroller handling sensor reading and relay control.
- **MQ-6 Gas Sensor:** Detects gas concentration.
- **Relay Module & Prototype Solenoid Valve:** Electromechanical control of the gas flow.
- **SIM800L / GSM / WiFi:** Network paths for communicating with the backend.
- **Supabase (PostgreSQL):** The central database managing users, devices, telemetry, and security.
- **Supabase Edge Functions:** Serverless functions handling sensitive operations (e.g., `send-valve-command`, `device-sync`) using service-role privileges.
- **Flutter Application:** The cross-platform mobile app for user interaction.

## Safety Architecture
**Local Safety Priority:** The system is designed such that local ESP32 gas detection and safety response **always** have priority over network or remote commands. If a gas leak is detected, the ESP32 will force the valve CLOSED regardless of any pending remote commands. Remote OPEN commands will be rejected or ignored if local sensors read unsafe gas levels.

## Valve Security
Remote valve actuation is highly restricted:
- **4-Digit SENZHUB PIN:** Required for all manual valve operations.
- **PIN-Protected CLOSE:** Closing the valve requires the user's PIN.
- **PIN + OTP-Protected OPEN:** Opening the valve requires both the user's PIN and a short-lived One-Time Password (OTP).
- **Server-Side Verification:** PINs and OTPs are cryptographically hashed and verified server-side via secure RPCs; the client never receives the raw verification hashes.
- **OTP Challenge Lifecycle:** OTPs have strict expiration times and attempt limits.

## Technology Stack
- **Frontend:** Flutter / Dart
- **Backend & Database:** Supabase / PostgreSQL
- **Serverless Compute:** Deno / Supabase Edge Functions
- **Hardware/IoT:** ESP32 / Arduino C++ / SIM800L

## Hardware
The current physical prototype utilizes:
- ESP32 Microcontroller
- MQ-6 Gas Sensor
- SIM800L GSM Module
- Relay Module
- FA0520F 12V DC 3-way solenoid valve

**WARNING: CRITICAL HARDWARE DISCLAIMER:** 
The FA0520F solenoid valve is a prototype, air-only demonstration component. It is NOT for actual LPG. For production, the system requires an appropriately certified LPG-compatible safety shutoff valve/system selected and validated for the intended installation.

## Database & Backend
The PostgreSQL database uses migrations to define a robust schema:
- `profiles`, `organizations`, `organization_users`: Multi-tenant user management.
- `devices`, `device_readings`: Device provisioning and time-series telemetry.
- `device_commands`: Command queueing for the ESP32 to fetch via `device-sync`.
- `user_security`, `otp_challenges`: Highly restricted tables for storing PIN/OTP hashes.

Edge Functions (e.g., `send-valve-command`, `device-sync`) execute with service-role permissions to safely broker communication between the mobile app, the database, and the IoT hardware.

## Security
- **Row Level Security (RLS):** RLS is configured on `profiles`, `organizations`, `organization_users`, `locations`, `devices`, `device_readings`, `alerts`, `valve_events`, and `diagnostics`. Users can only access data belonging to organizations they are a member of.
- **Service-Role Isolation:** Security tables (`user_security`, `otp_challenges`, `device_secrets`) completely bypass RLS and block public/authenticated access. They are only accessible via Edge Functions using the service-role key or strict `SECURITY DEFINER` RPCs.
- **Cryptographic Hashing:** PINs and OTPs are hashed using `pgcrypto` (`crypt(pin, gen_salt('bf'))`). No plaintext PIN/OTP persistence exists.
- **Secret Management:** Device secrets are securely stored and validated during `device-sync`.

## Project Structure
```
senzhubmobileapplication/
  android/                     # Android native code
  assets/                      # Images, fonts, and static assets
  docs/                        # Technical documentation (Architecture, API, Hardware, Security)
  ios/                         # iOS native code
  lib/                         # Flutter Dart source code
  linux/                       # Linux native code
  macos/                       # macOS native code
  supabase/                    # Backend configuration (migrations, edge functions)
  test/                        # Flutter unit and widget tests
  web/                         # Web build code
  windows/                     # Windows native code
  .env.example                 # Environment variable template
  pubspec.yaml                 # Flutter dependencies
```

## Setup Instructions
### 1. Prerequisites
- Flutter SDK (^3.13.4)
- Supabase CLI
- Docker (for local Supabase instance)

### 2. Environment Variables
Copy `.env.example` to `.env` and fill in your values.
```bash
cp .env.example .env
```
**Important:** Real secrets must remain outside Git. The `.env.example` file acts as a safe template. Never place real Supabase service-role keys, Twilio credentials, device secrets, passwords, or tokens in the repository.

### 3. Backend Setup (Local Supabase)
Start the local Supabase stack and apply migrations:
```bash
supabase start
supabase db reset
```
Serve the edge functions locally:
```bash
supabase functions serve
```

### 4. Flutter Setup
Install dependencies:
```bash
flutter pub get
```
Run the application on an Android emulator or physical device:
```bash
flutter run
```

## Testing
Flutter UI tests are tracked under the `test/` directory (e.g., `test/widget_test.dart`).
To run standard Flutter tests:
```bash
flutter test
```

## Current Implementation Status
**IMPLEMENTED / WORKING PROTOTYPE:**
- Flutter application
- Supabase backend
- authentication
- organization/device architecture
- secure valve command flow
- PIN security
- OTP challenge security lifecycle
- device-sync architecture
- local ESP32 safety logic

**IN PROGRESS / NOT PRODUCTION READY:**
- Twilio SMS OTP delivery integration
- full two-way GSM/SIM800L integration with backend
- production LPG-certified valve
- calibrated production gas measurement
- production deployment/hardening
