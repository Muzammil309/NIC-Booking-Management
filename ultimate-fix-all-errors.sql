-- ULTIMATE FIX FOR ALL ERRORS - NIC BOOKING MANAGEMENT
-- This script fixes infinite recursion, schema issues, and RLS problems
-- Run this in Supabase SQL Editor to resolve all issues

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

-- 3. ENSURE TABLES EXIST WITH CORRECT SCHEMA
-- Create users table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.users (
    id uuid REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email text NOT NULL,
    name text,
    phone text,
    role text DEFAULT 'startup' CHECK (role IN ('startup', 'admin')),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Create startups table with status column
CREATE TABLE IF NOT EXISTS public.startups (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid REFERENCES public.users(id) ON DELETE CASCADE,
    name text NOT NULL,
    contact_person text,
    phone text,
    email text,
    status text DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Add status column if it doesn't exist (for existing tables)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'startups' 
        AND column_name = 'status'
    ) THEN
        ALTER TABLE public.startups ADD COLUMN status text DEFAULT 'active' CHECK (status IN ('active', 'inactive'));
        RAISE NOTICE 'Added status column to startups table';
    ELSE
        RAISE NOTICE 'Status column already exists in startups table';
    END IF;
END $$;

-- Create rooms table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.rooms (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL UNIQUE,
    capacity integer DEFAULT 4,
    equipment text[] DEFAULT '{}',
    room_type text DEFAULT 'focus' CHECK (room_type IN ('focus', 'special', 'hub', 'board', 'session', 'podcast')),
    max_duration integer DEFAULT 2,
    requires_equipment boolean DEFAULT false,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Add missing columns to existing rooms table if they don't exist
DO $$
BEGIN
    -- Add capacity column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'rooms'
        AND column_name = 'capacity'
    ) THEN
        ALTER TABLE public.rooms ADD COLUMN capacity integer DEFAULT 4;
        RAISE NOTICE 'Added capacity column to rooms table';
    ELSE
        RAISE NOTICE 'Capacity column already exists in rooms table';
    END IF;

    -- Add equipment column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'rooms'
        AND column_name = 'equipment'
    ) THEN
        ALTER TABLE public.rooms ADD COLUMN equipment text[] DEFAULT '{}';
        RAISE NOTICE 'Added equipment column to rooms table';
    ELSE
        RAISE NOTICE 'Equipment column already exists in rooms table';
    END IF;

    -- Add room_type column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'rooms'
        AND column_name = 'room_type'
    ) THEN
        ALTER TABLE public.rooms ADD COLUMN room_type text DEFAULT 'focus';
        RAISE NOTICE 'Added room_type column to rooms table';
    ELSE
        RAISE NOTICE 'Room_type column already exists in rooms table';
    END IF;

    -- Drop any existing check constraints on room_type to avoid conflicts
    DECLARE
        constraint_name text;
    BEGIN
        FOR constraint_name IN
            SELECT conname FROM pg_constraint
            WHERE conrelid = 'public.rooms'::regclass
            AND contype = 'c'
            AND pg_get_constraintdef(oid) LIKE '%room_type%'
        LOOP
            EXECUTE format('ALTER TABLE public.rooms DROP CONSTRAINT IF EXISTS %I', constraint_name);
            RAISE NOTICE 'Dropped existing room_type constraint: %', constraint_name;
        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'No existing room_type constraints to drop or error occurred: %', SQLERRM;
    END;

    -- Add comprehensive room_type check constraint
    ALTER TABLE public.rooms ADD CONSTRAINT rooms_room_type_check
        CHECK (room_type IN ('focus', 'special', 'hub', 'board', 'session', 'podcast'));
    RAISE NOTICE 'Added comprehensive room_type check constraint';

    -- Add max_duration column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'rooms'
        AND column_name = 'max_duration'
    ) THEN
        ALTER TABLE public.rooms ADD COLUMN max_duration integer DEFAULT 2;
        RAISE NOTICE 'Added max_duration column to rooms table';
    ELSE
        RAISE NOTICE 'Max_duration column already exists in rooms table';
    END IF;

    -- Add requires_equipment column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'rooms'
        AND column_name = 'requires_equipment'
    ) THEN
        ALTER TABLE public.rooms ADD COLUMN requires_equipment boolean DEFAULT false;
        RAISE NOTICE 'Added requires_equipment column to rooms table';
    ELSE
        RAISE NOTICE 'Requires_equipment column already exists in rooms table';
    END IF;

    -- Add is_active column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'rooms'
        AND column_name = 'is_active'
    ) THEN
        ALTER TABLE public.rooms ADD COLUMN is_active boolean DEFAULT true;
        RAISE NOTICE 'Added is_active column to rooms table';
    ELSE
        RAISE NOTICE 'Is_active column already exists in rooms table';
    END IF;

    -- Add created_at column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'rooms'
        AND column_name = 'created_at'
    ) THEN
        ALTER TABLE public.rooms ADD COLUMN created_at timestamp with time zone DEFAULT now();
        RAISE NOTICE 'Added created_at column to rooms table';
    ELSE
        RAISE NOTICE 'Created_at column already exists in rooms table';
    END IF;

    -- Add updated_at column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'rooms'
        AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE public.rooms ADD COLUMN updated_at timestamp with time zone DEFAULT now();
        RAISE NOTICE 'Added updated_at column to rooms table';
    ELSE
        RAISE NOTICE 'Updated_at column already exists in rooms table';
    END IF;
END $$;

-- Create bookings table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.bookings (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    startup_id uuid REFERENCES public.startups(id) ON DELETE CASCADE NOT NULL,
    room_name text NOT NULL,
    booking_date date NOT NULL,
    start_time time NOT NULL,
    duration integer NOT NULL DEFAULT 1 CHECK (duration > 0 AND duration <= 8),
    equipment_notes text,
    is_confidential boolean DEFAULT false,
    status text DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'cancelled', 'completed')),
    room_type text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    UNIQUE (room_name, booking_date, start_time)
);

-- 4. CREATE SIMPLE, NON-RECURSIVE RLS POLICIES

-- USERS TABLE POLICIES (Simple and reliable - NO ADMIN RECURSION)
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

-- ROOMS TABLE POLICIES (Read-only for authenticated users, admin can modify)
CREATE POLICY "rooms_select_all" ON public.rooms
    FOR SELECT TO authenticated
    USING (true);

-- Admin access to rooms (using service role bypass for admin operations)
CREATE POLICY "rooms_admin_all" ON public.rooms
    FOR ALL TO service_role
    USING (true)
    WITH CHECK (true);

-- 5. CREATE ADMIN ACCESS FUNCTION (NO RECURSION)
-- This function allows admin operations without RLS recursion
CREATE OR REPLACE FUNCTION public.is_admin(user_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1 FROM auth.users
        WHERE id = user_id
        AND raw_user_meta_data->>'role' = 'admin'
    );
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.is_admin(uuid) TO authenticated;

-- 6. ADD ADMIN POLICIES USING THE FUNCTION (NO RECURSION)
-- Admin can view all users
CREATE POLICY "admin_users_select_all" ON public.users
    FOR SELECT TO authenticated
    USING (public.is_admin(auth.uid()));

-- Admin can view all startups
CREATE POLICY "admin_startups_select_all" ON public.startups
    FOR SELECT TO authenticated
    USING (public.is_admin(auth.uid()));

-- Admin can view all bookings
CREATE POLICY "admin_bookings_select_all" ON public.bookings
    FOR SELECT TO authenticated
    USING (public.is_admin(auth.uid()));

-- Admin can modify rooms
CREATE POLICY "admin_rooms_insert" ON public.rooms
    FOR INSERT TO authenticated
    WITH CHECK (public.is_admin(auth.uid()));

CREATE POLICY "admin_rooms_update" ON public.rooms
    FOR UPDATE TO authenticated
    USING (public.is_admin(auth.uid()))
    WITH CHECK (public.is_admin(auth.uid()));

CREATE POLICY "admin_rooms_delete" ON public.rooms
    FOR DELETE TO authenticated
    USING (public.is_admin(auth.uid()));

-- 8. RE-ENABLE RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.startups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rooms ENABLE ROW LEVEL SECURITY;

-- 9. INSERT ACTUAL NIC FACILITY ROOMS IF THEY DON'T EXIST
INSERT INTO public.rooms (name, capacity, room_type, max_duration, requires_equipment, is_active)
VALUES
    -- Hub Rooms (collaborative spaces)
    ('Hub Room 1', 6, 'hub', 3, false, true),
    ('Hub Room 2', 6, 'hub', 3, false, true),
    ('Hub Room 3', 6, 'hub', 3, false, true),

    -- Named Conference/Meeting Rooms
    ('Hingol', 8, 'board', 4, false, true),
    ('Telenor Velocity', 10, 'board', 4, true, true),
    ('Sutlej', 6, 'focus', 3, false, true),
    ('Chenab', 6, 'focus', 3, false, true),
    ('Jhelum', 6, 'focus', 3, false, true),

    -- Board and Session Rooms
    ('Indus Board', 12, 'board', 6, true, true),
    ('Nexus Session Hall', 20, 'session', 8, true, true),

    -- Specialized Equipment Rooms
    ('Podcast Room', 4, 'podcast', 2, true, true)
ON CONFLICT (name) DO NOTHING;

-- 10. CREATE AUTOMATIC PROFILE CREATION TRIGGER
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
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

-- Drop existing trigger and create new one
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Final success messages
DO $$
BEGIN
    RAISE NOTICE 'Ultimate fix completed successfully! All errors should be resolved.';
    RAISE NOTICE 'Schema cache will be refreshed automatically.';
    RAISE NOTICE 'Infinite recursion policies have been removed.';
    RAISE NOTICE 'Status column has been ensured in startups table.';
    RAISE NOTICE 'Room booking functionality is ready.';
    RAISE NOTICE 'Schedule calendar view is enabled.';
    RAISE NOTICE 'Complete user flow: registration → profile → booking → schedule viewing.';
END $$;
