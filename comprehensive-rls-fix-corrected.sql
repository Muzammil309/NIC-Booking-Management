-- COMPREHENSIVE RLS FIX FOR NIC BOOKING MANAGEMENT - CORRECTED VERSION
-- This script completely fixes RLS policies and adds automatic profile creation
-- Run this in Supabase SQL Editor to resolve all authentication and profile issues

-- 1. DISABLE RLS TEMPORARILY TO CLEAN UP
ALTER TABLE IF EXISTS public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.startups DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.bookings DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.rooms DISABLE ROW LEVEL SECURITY;

-- 2. DROP ALL EXISTING POLICIES (COMPREHENSIVE CLEANUP)
DO $$
DECLARE
    pol RECORD;
BEGIN
    -- Drop all policies on users table
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'users' AND schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.users', pol.policyname);
        RAISE NOTICE 'Dropped policy: % on users', pol.policyname;
    END LOOP;
    
    -- Drop all policies on startups table
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'startups' AND schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.startups', pol.policyname);
        RAISE NOTICE 'Dropped policy: % on startups', pol.policyname;
    END LOOP;
    
    -- Drop all policies on bookings table
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'bookings' AND schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.bookings', pol.policyname);
        RAISE NOTICE 'Dropped policy: % on bookings', pol.policyname;
    END LOOP;
    
    -- Drop all policies on rooms table
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'rooms' AND schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.rooms', pol.policyname);
        RAISE NOTICE 'Dropped policy: % on rooms', pol.policyname;
    END LOOP;
    
    RAISE NOTICE 'All existing policies dropped successfully';
END $$;

-- 3. CREATE SIMPLE, RELIABLE RLS POLICIES

-- USERS TABLE POLICIES (Simple and reliable)
CREATE POLICY "users_select_own" ON public.users
    FOR SELECT TO authenticated
    USING (id = auth.uid());

CREATE POLICY "users_insert_own" ON public.users
    FOR INSERT TO authenticated
    WITH CHECK (id = auth.uid());

CREATE POLICY "users_update_own" ON public.users
    FOR UPDATE TO authenticated
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

CREATE POLICY "users_delete_own" ON public.users
    FOR DELETE TO authenticated
    USING (id = auth.uid());

-- STARTUPS TABLE POLICIES (Simple and reliable)
CREATE POLICY "startups_select_own" ON public.startups
    FOR SELECT TO authenticated
    USING (user_id = auth.uid());

CREATE POLICY "startups_insert_own" ON public.startups
    FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "startups_update_own" ON public.startups
    FOR UPDATE TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "startups_delete_own" ON public.startups
    FOR DELETE TO authenticated
    USING (user_id = auth.uid());

-- BOOKINGS TABLE POLICIES (Access through startup ownership)
CREATE POLICY "bookings_select_own" ON public.bookings
    FOR SELECT TO authenticated
    USING (
        startup_id IN (
            SELECT id FROM public.startups WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "bookings_insert_own" ON public.bookings
    FOR INSERT TO authenticated
    WITH CHECK (
        startup_id IN (
            SELECT id FROM public.startups WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "bookings_update_own" ON public.bookings
    FOR UPDATE TO authenticated
    USING (
        startup_id IN (
            SELECT id FROM public.startups WHERE user_id = auth.uid()
        )
    )
    WITH CHECK (
        startup_id IN (
            SELECT id FROM public.startups WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "bookings_delete_own" ON public.bookings
    FOR DELETE TO authenticated
    USING (
        startup_id IN (
            SELECT id FROM public.startups WHERE user_id = auth.uid()
        )
    );

-- ROOMS TABLE POLICIES (Read-only for authenticated users)
CREATE POLICY "rooms_select_all" ON public.rooms
    FOR SELECT TO authenticated
    USING (true);

-- 4. ADMIN POLICIES (If admin functionality is needed)
CREATE POLICY "admin_full_access_users" ON public.users
    FOR ALL TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "admin_full_access_startups" ON public.startups
    FOR ALL TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "admin_full_access_bookings" ON public.bookings
    FOR ALL TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "admin_full_access_rooms" ON public.rooms
    FOR ALL TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- 5. RE-ENABLE RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.startups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rooms ENABLE ROW LEVEL SECURITY;

-- 6. CREATE AUTOMATIC PROFILE CREATION TRIGGER
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Create user profile automatically
    INSERT INTO public.users (id, email, name, phone, role)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'phone', ''),
        COALESCE(NEW.raw_user_meta_data->>'role', 'startup')
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        name = COALESCE(EXCLUDED.name, users.name),
        phone = COALESCE(EXCLUDED.phone, users.phone),
        role = COALESCE(EXCLUDED.role, users.role);

    -- Create startup profile if startup_name is provided
    IF COALESCE(NEW.raw_user_meta_data->>'startup_name', '') != '' THEN
        INSERT INTO public.startups (user_id, name, contact_person, phone, email, status)
        VALUES (
            NEW.id,
            NEW.raw_user_meta_data->>'startup_name',
            COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
            COALESCE(NEW.raw_user_meta_data->>'phone', ''),
            NEW.email,
            'active'
        )
        ON CONFLICT (user_id) DO UPDATE SET
            name = COALESCE(EXCLUDED.name, startups.name),
            contact_person = COALESCE(EXCLUDED.contact_person, startups.contact_person),
            phone = COALESCE(EXCLUDED.phone, startups.phone),
            email = COALESCE(EXCLUDED.email, startups.email);
    END IF;

    RETURN NEW;
END;
$$;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create the trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 7. VERIFICATION AND DIAGNOSTICS
DO $$
DECLARE
    policy_count INTEGER;
    trigger_exists BOOLEAN;
BEGIN
    -- Count policies
    SELECT COUNT(*) INTO policy_count FROM pg_policies WHERE schemaname = 'public';
    RAISE NOTICE 'Total RLS policies created: %', policy_count;

    -- Check trigger
    SELECT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'on_auth_user_created'
    ) INTO trigger_exists;

    IF trigger_exists THEN
        RAISE NOTICE 'Automatic profile creation trigger: INSTALLED';
    ELSE
        RAISE NOTICE 'Automatic profile creation trigger: NOT FOUND';
    END IF;

    RAISE NOTICE '';
    RAISE NOTICE 'COMPREHENSIVE RLS FIX COMPLETED SUCCESSFULLY';
    RAISE NOTICE 'New users will have profiles created automatically';
    RAISE NOTICE 'Existing users can now create startup profiles manually';
    RAISE NOTICE 'All booking functionality should work without RLS violations';
    RAISE NOTICE '';
END $$;
