# SENZHUB Test Cases

This document outlines the testing strategy and specific test cases for the SENZHUB system.

## Test Strategy Overview
The testing spans across multiple layers:
1. **Automated Tests:** Flutter UI widget tests and backend logic verification.
2. **Functional Tests (Manual):** User flows in the Flutter mobile application.
3. **Security Tests (Manual):** Validation of the PIN and OTP logic, RLS, and Edge Functions.
4. **Hardware/Integration Tests (Manual):** Verification of the ESP32 safety priority and GSM sync logic.

---

## Test Cases

| Test ID | Test Area | Test Description | Preconditions | Steps | Expected Result | Test Type | Status |
|---|---|---|---|---|---|---|---|
| AUTO-001 | Frontend | App Initialization and Widget Mounting | Flutter environment configured | Run `flutter test test/widget_test.dart` | Tests pass, verifying the main app widget loads without errors. | Automated | VERIFIED |
| FUNC-001 | Auth | Account Registration | User does not have an account | 1. Open App<br>2. Tap Sign Up<br>3. Enter valid email/password | User is registered, logged in, and profile is created. | Manual | IMPLEMENTED - NOT MANUALLY VERIFIED |
| FUNC-002 | Auth | Mandatory 4-digit SENZHUB PIN setup | User is registered but has no PIN | 1. Complete login<br>2. App prompts for PIN setup<br>3. Enter a valid 4-digit demo PIN<br>4. Confirm the PIN | PIN is hashed and saved securely. App proceeds to dashboard. | Manual | IMPLEMENTED - NOT MANUALLY VERIFIED |
| SEC-001 | Security | PIN-protected valve CLOSE | Device is ONLINE, valve is OPEN | 1. Tap CLOSE valve<br>2. Enter correct 4-digit demo PIN | Command is queued as PENDING. | Manual | IMPLEMENTED - NOT MANUALLY VERIFIED |
| SEC-002 | Security | PIN + OTP valve OPEN | Device is ONLINE, valve is CLOSED | 1. Tap OPEN valve<br>2. Enter correct PIN<br>3. Enter correct OTP | Command is queued as PENDING. | Manual | IMPLEMENTED - NOT MANUALLY VERIFIED |
| SEC-003 | Security | Invalid PIN attempt | Device is ONLINE | 1. Tap CLOSE valve<br>2. Enter wrong PIN | Edge Function returns 403 Forbidden. Valve state unchanged. | Security (Manual) | IMPLEMENTED - NOT MANUALLY VERIFIED |
| SEC-004 | Security | Invalid/Expired OTP | Device is ONLINE, valve CLOSED | 1. Tap OPEN valve<br>2. Enter correct PIN<br>3. Enter expired or incorrect OTP | Edge function returns 403. Challenge attempt increments. | Security (Manual) | IMPLEMENTED - NOT MANUALLY VERIFIED |
| SEC-005 | Security | OTP attempt limits | User requests OPEN | 1. Submit incorrect OTP 3 times | OTP challenge status transitions to FAILED. Further attempts with this OTP hash are blocked. | Security (Manual) | IMPLEMENTED - NOT MANUALLY VERIFIED |
| SEC-006 | Security | Unauthorized valve command | User is VIEWER role | 1. Intercept request and try to POST to `/send-valve-command` | Edge function returns 403 Forbidden due to role check. | Security (Manual) | IMPLEMENTED - NOT MANUALLY VERIFIED |
| HW-001 | Hardware | Command Lifecycle (Device Sync) | Command is PENDING in DB | 1. Wait for ESP32 sync interval<br>2. `device-sync` pulls PENDING command | ESP32 receives command, executes relay, sends EXECUTED status. | Integration | IMPLEMENTED - NOT MANUALLY VERIFIED |
| HW-002 | Hardware | Local gas-danger safety response | ESP32 is powered on | 1. Expose MQ-6 to high gas concentration exceeding danger threshold. | ESP32 detects the DANGER condition and activates the local safety response independently of network availability. | Hardware | IMPLEMENTED - NOT MANUALLY VERIFIED |
| HW-003 | Hardware | Remote command interaction with local safety priority | MQ-6 reading is DANGER | 1. Send remote OPEN command via App<br>2. Wait for ESP32 sync | ESP32 receives OPEN command but rejects it due to active local DANGER state. | Hardware | IMPLEMENTED - NOT MANUALLY VERIFIED |
| INT-001 | Integration | Twilio SMS OTP delivery | User requests OPEN command | 1. User requests OTP<br>2. Edge function generates OTP<br>3. Twilio sends SMS | SMS is delivered to user's registered phone. | Integration | IN PROGRESS |
| HW-004 | Hardware | Two-way GSM/SIM800L Edge Function integration | ESP32 out of WiFi range | 1. Command queued<br>2. ESP32 syncs via GSM | `device-sync` returns commands via GSM cellular network. | Integration | IN PROGRESS |
