-- ===== ADMIN BOOKING MANAGEMENT =====
-- Adds admin-only booking management functions, audit logging, and columns

-- 1) Add audit columns to bookings
ALTER TABLE public.bookings
ADD COLUMN IF NOT EXISTS cancelled_by uuid,
ADD COLUMN IF NOT EXISTS cancelled_reason text,
ADD COLUMN IF NOT EXISTS cancelled_at timestamptz;

-- 2) Audit log table for admin actions
CREATE TABLE IF NOT EXISTS public.admin_audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id uuid NOT NULL,
  action text NOT NULL,
  entity text NOT NULL,
  entity_id uuid NOT NULL,
  details jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- 3) Function: ensure caller is admin
CREATE OR REPLACE FUNCTION public.assert_admin()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  _role text;
BEGIN
  SELECT role INTO _role FROM public.users WHERE id = auth.uid();
  IF _role IS DISTINCT FROM 'admin' THEN
    RAISE EXCEPTION 'Not authorized: admin role required';
  END IF;
END; $$;

-- 4) Cancel booking (admin)
CREATE OR REPLACE FUNCTION public.cancel_booking_admin(p_booking_id uuid, p_reason text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  _booking public.bookings%ROWTYPE;
BEGIN
  PERFORM public.assert_admin();

  SELECT * INTO _booking FROM public.bookings WHERE id = p_booking_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found';
  END IF;

  UPDATE public.bookings
  SET status = 'cancelled',
      cancelled_by = auth.uid(),
      cancelled_reason = COALESCE(p_reason, 'Cancelled by admin'),
      cancelled_at = now()
  WHERE id = p_booking_id;

  INSERT INTO public.admin_audit_logs(admin_id, action, entity, entity_id, details)
  VALUES (auth.uid(), 'cancel_booking', 'bookings', p_booking_id, jsonb_build_object('reason', p_reason));

  RETURN jsonb_build_object('ok', true);
END; $$;

-- 5) Reschedule booking (admin)
CREATE OR REPLACE FUNCTION public.reschedule_booking_admin(
  p_booking_id uuid,
  p_new_date date,
  p_new_start time,
  p_new_duration integer
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  _booking public.bookings%ROWTYPE;
  _validation jsonb;
BEGIN
  PERFORM public.assert_admin();

  SELECT * INTO _booking FROM public.bookings WHERE id = p_booking_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found';
  END IF;

  -- Validate constraints for the room
  _validation := public.validate_booking_constraints(_booking.room_name, p_new_date, p_new_start, p_new_duration);
  IF (_validation->>'valid')::boolean IS NOT TRUE THEN
    RETURN jsonb_build_object('ok', false, 'errors', _validation->'errors');
  END IF;

  UPDATE public.bookings
  SET booking_date = p_new_date,
      start_time = p_new_start,
      duration = p_new_duration
  WHERE id = p_booking_id;

  INSERT INTO public.admin_audit_logs(admin_id, action, entity, entity_id, details)
  VALUES (auth.uid(), 'reschedule_booking', 'bookings', p_booking_id,
          jsonb_build_object('new_date', p_new_date, 'new_start', p_new_start, 'new_duration', p_new_duration));

  RETURN jsonb_build_object('ok', true);
END; $$;

-- 6) Grants
GRANT USAGE, SELECT ON SEQUENCE admin_audit_logs_id_seq TO authenticated;
GRANT SELECT, INSERT ON public.admin_audit_logs TO authenticated;
GRANT EXECUTE ON FUNCTION public.cancel_booking_admin(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.reschedule_booking_admin(uuid, date, time, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.assert_admin() TO authenticated;

