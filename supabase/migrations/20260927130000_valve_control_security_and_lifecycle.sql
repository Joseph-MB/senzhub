-- Migration: 20260927130000_valve_control_security_and_lifecycle.sql
-- Description: Add foreign keys, command lifecycle tracking, RLS policies, and realtime publication for valve control.

-- 1. Foreign Key Constraints for device_commands
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'device_commands_device_id_fkey'
    ) THEN
        ALTER TABLE public.device_commands
          ADD CONSTRAINT device_commands_device_id_fkey
          FOREIGN KEY (device_id) REFERENCES public.devices(id) ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'device_commands_requested_by_fkey'
    ) THEN
        ALTER TABLE public.device_commands
          ADD CONSTRAINT device_commands_requested_by_fkey
          FOREIGN KEY (requested_by) REFERENCES public.profiles(id) ON DELETE SET NULL;
    END IF;
END $$;

-- 2. Lifecycle columns for device_commands
ALTER TABLE public.device_commands
  ADD COLUMN IF NOT EXISTS acknowledged_at timestamptz,
  ADD COLUMN IF NOT EXISTS failed_at timestamptz,
  ADD COLUMN IF NOT EXISTS failure_reason text,
  ADD COLUMN IF NOT EXISTS expires_at timestamptz;

-- 3. Check Constraint for device_commands.status
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'device_commands_status_check'
    ) THEN
        ALTER TABLE public.device_commands
          ADD CONSTRAINT device_commands_status_check
          CHECK (status IN ('PENDING', 'SENT', 'EXECUTED', 'FAILED', 'TIMED_OUT'));
    END IF;
END $$;

-- 4. Enable RLS on device_commands (idempotent)
ALTER TABLE public.device_commands ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies for device_commands
DROP POLICY IF EXISTS "Users can view commands for their organization devices" ON public.device_commands;
CREATE POLICY "Users can view commands for their organization devices"
ON public.device_commands FOR SELECT
TO authenticated
USING (
  device_id IN (
    SELECT d.id FROM public.devices d
    WHERE d.organization_id IN (
      SELECT ou.organization_id FROM public.organization_users ou
      WHERE ou.user_id = auth.uid()
    )
  )
);

DROP POLICY IF EXISTS "Users can insert commands for their organization devices" ON public.device_commands;
CREATE POLICY "Users can insert commands for their organization devices"
ON public.device_commands FOR INSERT
TO authenticated
WITH CHECK (
  device_id IN (
    SELECT d.id FROM public.devices d
    WHERE d.organization_id IN (
      SELECT ou.organization_id FROM public.organization_users ou
      WHERE ou.user_id = auth.uid()
      AND ou.role IN ('OWNER'::public.org_role, 'ADMIN'::public.org_role, 'OPERATOR'::public.org_role)
    )
  )
);

-- 6. RLS Policy for valve_events INSERT
DROP POLICY IF EXISTS "Users can insert valve events for their organization devices" ON public.valve_events;
CREATE POLICY "Users can insert valve events for their organization devices"
ON public.valve_events FOR INSERT
TO authenticated
WITH CHECK (
  device_id IN (
    SELECT d.id FROM public.devices d
    WHERE d.organization_id IN (
      SELECT ou.organization_id FROM public.organization_users ou
      WHERE ou.user_id = auth.uid()
      AND ou.role IN ('OWNER'::public.org_role, 'ADMIN'::public.org_role, 'OPERATOR'::public.org_role)
    )
  )
);

-- 7. Add device_commands to Supabase Realtime publication
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
          AND schemaname = 'public'
          AND tablename = 'device_commands'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.device_commands;
    END IF;
END $$;

-- 8. Table permissions
REVOKE ALL ON TABLE public.device_commands FROM anon;
GRANT SELECT, INSERT ON TABLE public.device_commands TO authenticated;
GRANT ALL ON TABLE public.device_commands TO service_role;
