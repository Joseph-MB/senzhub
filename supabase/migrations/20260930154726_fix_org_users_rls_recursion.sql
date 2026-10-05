CREATE OR REPLACE FUNCTION public.get_user_organization_ids()
RETURNS SETOF uuid
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT organization_id
    FROM public.organization_users
    WHERE user_id = auth.uid();
$$;

DROP POLICY IF EXISTS "Users can view members of their organizations"
ON public.organization_users;

CREATE POLICY "Users can view members of their organizations"
ON public.organization_users
FOR SELECT
TO authenticated
USING (
    organization_id IN (
        SELECT public.get_user_organization_ids()
    )
);
