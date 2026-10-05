-- Migration: 20261003092003_fix_rpc_search_path.sql
-- Description: Fix the search_path of secure RPCs to include the "extensions" schema 
-- so they can resolve the pgcrypto functions (crypt, gen_salt).

CREATE OR REPLACE FUNCTION public.set_user_pin(p_user_id UUID, p_pin TEXT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
BEGIN
    IF length(p_pin) != 4 OR p_pin !~ '^[0-9]{4}$' THEN
        RAISE EXCEPTION 'PIN must be exactly 4 digits';
    END IF;

    -- Throws unique constraint violation if PIN already exists, preventing overwrite.
    INSERT INTO public.user_security (user_id, valve_pin_hash, updated_at)
    VALUES (p_user_id, crypt(p_pin, gen_salt('bf')), now());
END;
$$;

REVOKE EXECUTE ON FUNCTION public.set_user_pin(UUID, TEXT) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.set_user_pin(UUID, TEXT) FROM authenticated, anon;
GRANT EXECUTE ON FUNCTION public.set_user_pin(UUID, TEXT) TO service_role;


CREATE OR REPLACE FUNCTION public.update_user_pin(p_user_id UUID, p_pin TEXT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
BEGIN
    IF length(p_pin) != 4 OR p_pin !~ '^[0-9]{4}$' THEN
        RAISE EXCEPTION 'PIN must be exactly 4 digits';
    END IF;

    -- Upsert for resetting existing PIN
    INSERT INTO public.user_security (user_id, valve_pin_hash, updated_at)
    VALUES (p_user_id, crypt(p_pin, gen_salt('bf')), now())
    ON CONFLICT (user_id) DO UPDATE 
    SET valve_pin_hash = EXCLUDED.valve_pin_hash,
        updated_at = now();
END;
$$;

REVOKE EXECUTE ON FUNCTION public.update_user_pin(UUID, TEXT) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.update_user_pin(UUID, TEXT) FROM authenticated, anon;
GRANT EXECUTE ON FUNCTION public.update_user_pin(UUID, TEXT) TO service_role;


CREATE OR REPLACE FUNCTION public.verify_user_pin(p_user_id UUID, p_pin TEXT)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
    v_hash TEXT;
BEGIN
    SELECT valve_pin_hash INTO v_hash FROM public.user_security WHERE user_id = p_user_id;
    IF v_hash IS NULL THEN
        RETURN false;
    END IF;
    RETURN v_hash = crypt(p_pin, v_hash);
END;
$$;

REVOKE EXECUTE ON FUNCTION public.verify_user_pin(UUID, TEXT) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.verify_user_pin(UUID, TEXT) FROM authenticated, anon;
GRANT EXECUTE ON FUNCTION public.verify_user_pin(UUID, TEXT) TO service_role;


CREATE OR REPLACE FUNCTION public.create_otp_challenge(p_user_id UUID, p_device_id UUID, p_action public.valve_action, p_otp TEXT, p_expires_in_minutes INT)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
    v_challenge_id UUID;
BEGIN
    -- Invalidate any previous PENDING challenges for this user/device/action
    UPDATE public.otp_challenges 
    SET status = 'EXPIRED' 
    WHERE user_id = p_user_id 
      AND device_id = p_device_id 
      AND action = p_action 
      AND status = 'PENDING';

    INSERT INTO public.otp_challenges (user_id, device_id, action, otp_hash, expires_at)
    VALUES (
        p_user_id, 
        p_device_id, 
        p_action, 
        crypt(p_otp, gen_salt('bf')), 
        now() + (p_expires_in_minutes || ' minutes')::interval
    )
    RETURNING id INTO v_challenge_id;
    
    RETURN v_challenge_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.create_otp_challenge(UUID, UUID, public.valve_action, TEXT, INT) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.create_otp_challenge(UUID, UUID, public.valve_action, TEXT, INT) FROM authenticated, anon;
GRANT EXECUTE ON FUNCTION public.create_otp_challenge(UUID, UUID, public.valve_action, TEXT, INT) TO service_role;


CREATE OR REPLACE FUNCTION public.verify_and_consume_otp(p_user_id UUID, p_device_id UUID, p_action public.valve_action, p_otp TEXT)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
    v_challenge RECORD;
BEGIN
    -- Find the most recent pending challenge
    SELECT * INTO v_challenge
    FROM public.otp_challenges
    WHERE user_id = p_user_id 
      AND device_id = p_device_id 
      AND action = p_action
      AND status = 'PENDING'
    ORDER BY created_at DESC
    LIMIT 1
    FOR UPDATE; -- lock row to prevent race conditions

    IF NOT FOUND THEN
        RETURN false;
    END IF;

    -- Check expiry
    IF now() > v_challenge.expires_at THEN
        UPDATE public.otp_challenges SET status = 'EXPIRED' WHERE id = v_challenge.id;
        RETURN false;
    END IF;

    -- Check attempts
    IF v_challenge.attempts >= 3 THEN
        UPDATE public.otp_challenges SET status = 'FAILED' WHERE id = v_challenge.id;
        RETURN false;
    END IF;

    -- Verify hash
    IF v_challenge.otp_hash = crypt(p_otp, v_challenge.otp_hash) THEN
        UPDATE public.otp_challenges 
        SET status = 'CONSUMED', consumed_at = now(), attempts = attempts + 1
        WHERE id = v_challenge.id;
        RETURN true;
    ELSE
        UPDATE public.otp_challenges 
        SET attempts = attempts + 1,
            status = CASE WHEN attempts + 1 >= 3 THEN 'FAILED'::public.otp_status ELSE 'PENDING'::public.otp_status END
        WHERE id = v_challenge.id;
        RETURN false;
    END IF;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.verify_and_consume_otp(UUID, UUID, public.valve_action, TEXT) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.verify_and_consume_otp(UUID, UUID, public.valve_action, TEXT) FROM authenticated, anon;
GRANT EXECUTE ON FUNCTION public.verify_and_consume_otp(UUID, UUID, public.valve_action, TEXT) TO service_role;