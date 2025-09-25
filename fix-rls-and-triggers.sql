-- Fix RLS, add safe policies, and create automatic profile-creation trigger
-- Run this in Supabase SQL Editor. Safe to re-run.

-- 1) Ensure RLS is enabled on key tables
alter table if exists public.users enable row level security;
alter table if exists public.startups enable row level security;
alter table if exists public.bookings enable row level security;

-- 2) Drop conflicting policies if they exist (idempotent)
DO $$
BEGIN
  -- users
  IF EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='users' AND policyname='Users can view own user') THEN
    EXECUTE 'DROP POLICY "Users can view own user" ON public.users';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='users' AND policyname='Users can insert own user') THEN
    EXECUTE 'DROP POLICY "Users can insert own user" ON public.users';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='users' AND policyname='Users can update own user') THEN
    EXECUTE 'DROP POLICY "Users can update own user" ON public.users';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='users' AND policyname='Users can delete own user') THEN
    EXECUTE 'DROP POLICY "Users can delete own user" ON public.users';
  END IF;

  -- startups
  IF EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='startups' AND policyname='Startups select own') THEN
    EXECUTE 'DROP POLICY "Startups select own" ON public.startups';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='startups' AND policyname='Startups insert own') THEN
    EXECUTE 'DROP POLICY "Startups insert own" ON public.startups';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='startups' AND policyname='Startups update own') THEN
    EXECUTE 'DROP POLICY "Startups update own" ON public.startups';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='startups' AND policyname='Startups delete own') THEN
    EXECUTE 'DROP POLICY "Startups delete own" ON public.startups';
  END IF;

  -- bookings
  IF EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='bookings' AND policyname='Bookings select own startup') THEN
    EXECUTE 'DROP POLICY "Bookings select own startup" ON public.bookings';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='bookings' AND policyname='Bookings insert own startup') THEN
    EXECUTE 'DROP POLICY "Bookings insert own startup" ON public.bookings';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='bookings' AND policyname='Bookings update own startup') THEN
    EXECUTE 'DROP POLICY "Bookings update own startup" ON public.bookings';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='bookings' AND policyname='Bookings delete own startup') THEN
    EXECUTE 'DROP POLICY "Bookings delete own startup" ON public.bookings';
  END IF;
END $$ LANGUAGE plpgsql;

-- 3) (Re)create minimal, correct policies
-- users
CREATE POLICY "Users can view own user" ON public.users
  FOR SELECT TO authenticated
  USING (id = auth.uid());

CREATE POLICY "Users can insert own user" ON public.users
  FOR INSERT TO authenticated
  WITH CHECK (id = auth.uid());

CREATE POLICY "Users can update own user" ON public.users
  FOR UPDATE TO authenticated
  USING (id = auth.uid());

CREATE POLICY "Users can delete own user" ON public.users
  FOR DELETE TO authenticated
  USING (id = auth.uid());

-- startups
CREATE POLICY "Startups select own" ON public.startups
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Startups insert own" ON public.startups
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Startups update own" ON public.startups
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Startups delete own" ON public.startups
  FOR DELETE TO authenticated
  USING (user_id = auth.uid());

-- bookings (tie access to the caller's startup_id)
CREATE POLICY "Bookings select own startup" ON public.bookings
  FOR SELECT TO authenticated
  USING (
    startup_id IN (
      SELECT s.id FROM public.startups s WHERE s.user_id = auth.uid()
    )
  );

CREATE POLICY "Bookings insert own startup" ON public.bookings
  FOR INSERT TO authenticated
  WITH CHECK (
    startup_id IN (
      SELECT s.id FROM public.startups s WHERE s.user_id = auth.uid()
    )
  );

CREATE POLICY "Bookings update own startup" ON public.bookings
  FOR UPDATE TO authenticated
  USING (
    startup_id IN (
      SELECT s.id FROM public.startups s WHERE s.user_id = auth.uid()
    )
  );

CREATE POLICY "Bookings delete own startup" ON public.bookings
  FOR DELETE TO authenticated
  USING (
    startup_id IN (
      SELECT s.id FROM public.startups s WHERE s.user_id = auth.uid()
    )
  );

-- 4) Automatic profile creation on auth.users insert
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Ensure a users row exists
  INSERT INTO public.users (id, email, name, phone, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'phone', ''),
    COALESCE(NEW.raw_user_meta_data->>'role', 'startup')
  )
  ON CONFLICT (id) DO NOTHING;

  -- Create a startup row once if metadata provides a name
  IF COALESCE(NEW.raw_user_meta_data->>'startup_name', '') <> '' THEN
    INSERT INTO public.startups (user_id, name, contact_person, phone, email, status)
    SELECT
      NEW.id,
      NEW.raw_user_meta_data->>'startup_name',
      COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email,'@',1)),
      COALESCE(NEW.raw_user_meta_data->>'phone',''),
      NEW.email,
      'active'
    WHERE NOT EXISTS (
      SELECT 1 FROM public.startups s WHERE s.user_id = NEW.id
    );
  END IF;

  RETURN NEW;
END
$$;

-- Create trigger once
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'on_auth_user_created'
  ) THEN
    CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
  END IF;
END $$ LANGUAGE plpgsql;

-- 5) Messages (ASCII only)
DO $$
BEGIN
  RAISE NOTICE 'RLS policies created/updated.';
  RAISE NOTICE 'Automatic profile trigger installed.';
  RAISE NOTICE 'Signup can now complete without client-side inserts.';
END $$ LANGUAGE plpgsql;

