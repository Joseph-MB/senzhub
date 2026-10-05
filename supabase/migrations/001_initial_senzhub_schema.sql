-- SENZHUB Production Database Schema - Initial Migration
-- DO NOT EXECUTE - DESIGN REVIEW ONLY

-- 1. ENUMS
CREATE TYPE org_role AS ENUM ('OWNER', 'ADMIN', 'OPERATOR', 'VIEWER');
CREATE TYPE gas_status AS ENUM ('SAFE', 'WARNING', 'DANGER');
CREATE TYPE valve_status AS ENUM ('OPEN', 'CLOSED', 'SAFETY_LOCK');
CREATE TYPE power_source AS ENUM ('AC', 'BATTERY');
CREATE TYPE device_status AS ENUM ('ONLINE', 'OFFLINE');
CREATE TYPE alert_type AS ENUM (
    'GAS_WARNING', 'GAS_DANGER', 'GAS_CRITICAL', 
    'DEVICE_OFFLINE', 'LOW_BATTERY', 'SYSTEM_FAULT', 
    'GSM_FAULT', 'SENSOR_FAULT', 'VALVE_FAULT'
);
CREATE TYPE alert_severity AS ENUM ('INFO', 'WARNING', 'DANGER', 'CRITICAL');
CREATE TYPE valve_action AS ENUM ('OPEN', 'CLOSE');

-- 2. TABLES

-- Profiles extending auth.users
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Organizations
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Organization Membership
CREATE TABLE organization_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    role org_role NOT NULL DEFAULT 'VIEWER',
    UNIQUE(user_id, organization_id)
);

-- Locations
CREATE TABLE locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    address TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Devices (Operational State)
CREATE TABLE devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE RESTRICT,
    location_id UUID REFERENCES locations(id) ON DELETE SET NULL,
    device_name TEXT NOT NULL,
    serial_number TEXT NOT NULL UNIQUE,
    firmware_version TEXT,
    hardware_version TEXT,
    warning_threshold_ppm INT NOT NULL DEFAULT 3200 CHECK (warning_threshold_ppm > 0),
    danger_threshold_ppm INT NOT NULL DEFAULT 3700 CHECK (danger_threshold_ppm > warning_threshold_ppm),
    battery_percentage INT CHECK (battery_percentage >= 0 AND battery_percentage <= 100),
    battery_voltage NUMERIC,
    gsm_signal INT,
    gas_status gas_status NOT NULL DEFAULT 'SAFE',
    valve_status valve_status NOT NULL DEFAULT 'OPEN',
    power_source power_source NOT NULL DEFAULT 'AC',
    device_status device_status NOT NULL DEFAULT 'OFFLINE',
    last_communication_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Device Secrets (Isolated for Security)
CREATE TABLE device_secrets (
    device_id UUID PRIMARY KEY REFERENCES devices(id) ON DELETE CASCADE,
    secret TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Device Readings (Historical telemetry)
CREATE TABLE device_readings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id UUID NOT NULL REFERENCES devices(id) ON DELETE RESTRICT,
    gas_level_ppm INT NOT NULL CHECK (gas_level_ppm >= 0),
    battery_percentage INT CHECK (battery_percentage >= 0 AND battery_percentage <= 100),
    battery_voltage NUMERIC,
    gsm_signal_csq INT,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Alerts
CREATE TABLE alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id UUID NOT NULL REFERENCES devices(id) ON DELETE RESTRICT,
    alert_type alert_type NOT NULL,
    gas_level_ppm INT CHECK (gas_level_ppm >= 0),
    message TEXT NOT NULL,
    severity alert_severity NOT NULL,
    is_acknowledged BOOLEAN NOT NULL DEFAULT false,
    acknowledged_at TIMESTAMPTZ,
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Valve Events (Audit Log)
CREATE TABLE valve_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id UUID NOT NULL REFERENCES devices(id) ON DELETE RESTRICT,
    actor_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    action valve_action NOT NULL,
    reason TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Diagnostics
CREATE TABLE diagnostics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id UUID NOT NULL REFERENCES devices(id) ON DELETE RESTRICT,
    name TEXT NOT NULL,
    status TEXT NOT NULL,
    message TEXT,
    last_checked_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. INDEXES
CREATE INDEX idx_org_users_user_id ON organization_users(user_id);
CREATE INDEX idx_org_users_org_id ON organization_users(organization_id);
CREATE INDEX idx_locations_org_id ON locations(organization_id);
CREATE INDEX idx_devices_org_id ON devices(organization_id);
CREATE INDEX idx_devices_location_id ON devices(location_id);
CREATE INDEX idx_devices_serial_number ON devices(serial_number);

-- Composite indexes for time-series / chronological queries
CREATE INDEX idx_device_readings_device_time ON device_readings(device_id, recorded_at DESC);
CREATE INDEX idx_alerts_device_time ON alerts(device_id, created_at DESC);
CREATE INDEX idx_valve_events_device_time ON valve_events(device_id, created_at DESC);
CREATE INDEX idx_diagnostics_device_time ON diagnostics(device_id, last_checked_at DESC);

-- 4. ROW LEVEL SECURITY (RLS)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE organization_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_secrets ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_readings ENABLE ROW LEVEL SECURITY;
ALTER TABLE alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE valve_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE diagnostics ENABLE ROW LEVEL SECURITY;

-- Profiles
CREATE POLICY "Users can view own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

-- Organizations
CREATE POLICY "Users can view their organizations" ON organizations
    FOR SELECT USING (
        id IN (SELECT organization_id FROM organization_users WHERE user_id = auth.uid())
    );

-- Organization Users
CREATE POLICY "Users can view members of their organizations" ON organization_users
    FOR SELECT USING (
        organization_id IN (SELECT organization_id FROM organization_users WHERE user_id = auth.uid())
    );

-- Locations
CREATE POLICY "Users can view locations in their organizations" ON locations
    FOR SELECT USING (
        organization_id IN (SELECT organization_id FROM organization_users WHERE user_id = auth.uid())
    );

-- Devices
CREATE POLICY "Users can view devices in their organizations" ON devices
    FOR SELECT USING (
        organization_id IN (SELECT organization_id FROM organization_users WHERE user_id = auth.uid())
    );

-- Device Secrets: DO NOT create a SELECT policy for normal authenticated users. 
-- Only edge functions or service roles (which bypass RLS) should access this.

-- Child tables (Readings, Alerts, Valve Events, Diagnostics)
CREATE POLICY "Users can view readings of their organizations devices" ON device_readings
    FOR SELECT USING (
        device_id IN (
            SELECT id FROM devices WHERE organization_id IN (
                SELECT organization_id FROM organization_users WHERE user_id = auth.uid()
            )
        )
    );

CREATE POLICY "Users can view alerts of their organizations devices" ON alerts
    FOR SELECT USING (
        device_id IN (
            SELECT id FROM devices WHERE organization_id IN (
                SELECT organization_id FROM organization_users WHERE user_id = auth.uid()
            )
        )
    );

CREATE POLICY "Users can view valve events of their organizations devices" ON valve_events
    FOR SELECT USING (
        device_id IN (
            SELECT id FROM devices WHERE organization_id IN (
                SELECT organization_id FROM organization_users WHERE user_id = auth.uid()
            )
        )
    );

CREATE POLICY "Users can view diagnostics of their organizations devices" ON diagnostics
    FOR SELECT USING (
        device_id IN (
            SELECT id FROM devices WHERE organization_id IN (
                SELECT organization_id FROM organization_users WHERE user_id = auth.uid()
            )
        )
    );

-- NOTE: INSERT, UPDATE, and DELETE policies for all tables are intentionally deferred.
-- They will be implemented when application workflows and precise role boundaries 
-- (OWNER, ADMIN, OPERATOR, VIEWER) are finalized.
