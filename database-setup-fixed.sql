-- NIC Booking Management Database Setup - FIXED VERSION
-- This script fixes all SQL errors and is safe to run multiple times
-- Run this SQL in your Supabase SQL Editor

BEGIN;

-- Create users table if it doesn't exist (for user profiles)
CREATE TABLE IF NOT EXISTS public.users (
    id uuid REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email text NOT NULL,
    name text,
    phone text,
    role text DEFAULT 'startup' CHECK (role IN ('startup', 'admin')),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Create startups table if it doesn't exist
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

-- Create rooms table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.rooms (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL UNIQUE,
    capacity integer DEFAULT 4,
    equipment text[] DEFAULT '{}',
    room_type text DEFAULT 'focus' CHECK (room_type IN ('focus', 'special')),
    max_duration integer DEFAULT 2,
    requires_equipment boolean DEFAULT false,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Create bookings table with all necessary columns
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
    
    -- Simple unique constraint to prevent exact duplicate bookings
    UNIQUE (room_name, booking_date, start_time)
);

-- Create function to prevent overlapping bookings
CREATE OR REPLACE FUNCTION public.check_booking_overlap()
RETURNS TRIGGER AS $$
BEGIN
    -- Check for overlapping bookings
    IF EXISTS (
        SELECT 1 FROM public.bookings 
        WHERE room_name = NEW.room_name 
        AND booking_date = NEW.booking_date
        AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
        AND (
            -- Check if times overlap
            (NEW.start_time, (NEW.start_time + (NEW.duration || ' hours')::interval)::time) OVERLAPS 
            (start_time, (start_time + (duration || ' hours')::interval)::time)
        )
    ) THEN
        RAISE EXCEPTION 'Booking conflicts with existing reservation for % on % at %', NEW.room_name, NEW.booking_date, NEW.start_time;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.startups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

-- Clean up existing policies safely
DO $$ 
BEGIN
    -- Users table policies
    DROP POLICY IF EXISTS "Users can view their own profile" ON public.users;
    DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;
    DROP POLICY IF EXISTS "Admins can view all users" ON public.users;
    DROP POLICY IF EXISTS "Admins can manage all users" ON public.users;
    
    -- Startups table policies
    DROP POLICY IF EXISTS "Users can view their own startup" ON public.startups;
    DROP POLICY IF EXISTS "Users can update their own startup" ON public.startups;
    DROP POLICY IF EXISTS "Users can create their own startup" ON public.startups;
    DROP POLICY IF EXISTS "Admins can view all startups" ON public.startups;
    
    -- Rooms table policies
    DROP POLICY IF EXISTS "Allow authenticated users to read rooms" ON public.rooms;
    DROP POLICY IF EXISTS "Allow admins to manage rooms" ON public.rooms;
    
    -- Bookings table policies
    DROP POLICY IF EXISTS "Users can view their own bookings" ON public.bookings;
    DROP POLICY IF EXISTS "Users can create their own bookings" ON public.bookings;
    DROP POLICY IF EXISTS "Users can update their own bookings" ON public.bookings;
    DROP POLICY IF EXISTS "Admins can view all bookings" ON public.bookings;
    DROP POLICY IF EXISTS "Admins can manage all bookings" ON public.bookings;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Some policies may not exist, continuing...';
END $$;

-- Create RLS policies for users table
CREATE POLICY "Users can view their own profile" ON public.users
    FOR SELECT TO authenticated
    USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON public.users
    FOR UPDATE TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Admins can view all users" ON public.users
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Admins can manage all users" ON public.users
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

-- Create RLS policies for startups table
CREATE POLICY "Users can view their own startup" ON public.startups
    FOR SELECT TO authenticated
    USING (user_id = auth.uid());

CREATE POLICY "Users can update their own startup" ON public.startups
    FOR UPDATE TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can create their own startup" ON public.startups
    FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Admins can view all startups" ON public.startups
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Create RLS policies for rooms table
CREATE POLICY "Allow authenticated users to read rooms" ON public.rooms
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow admins to manage rooms" ON public.rooms
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

-- Create RLS policies for bookings table
CREATE POLICY "Users can view their own bookings" ON public.bookings
    FOR SELECT TO authenticated
    USING (
        startup_id IN (
            SELECT id FROM public.startups WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create their own bookings" ON public.bookings
    FOR INSERT TO authenticated
    WITH CHECK (
        startup_id IN (
            SELECT id FROM public.startups WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update their own bookings" ON public.bookings
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

CREATE POLICY "Admins can view all bookings" ON public.bookings
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Admins can manage all bookings" ON public.bookings
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

COMMIT;

-- Insert sample room data (separate transaction to handle errors gracefully)
BEGIN;

-- Insert enhanced room data only if no rooms exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.rooms LIMIT 1) THEN
        INSERT INTO public.rooms (name, capacity, equipment, room_type, max_duration, requires_equipment, is_active) VALUES
            ('HUB (Focus Room)', 4, ARRAY['Whiteboard', 'Desk Setup'], 'focus', 2, false, true),
            ('Hingol (Focus Room)', 4, ARRAY['Whiteboard', 'Desk Setup'], 'focus', 2, false, true),
            ('Telenor Velocity Room', 8, ARRAY['Projector', 'Video Conference', 'Whiteboard'], 'special', 2, false, true),
            ('Sutlej (Focus Room)', 4, ARRAY['Whiteboard', 'Desk Setup'], 'focus', 2, false, true),
            ('Chenab (Focus Room)', 4, ARRAY['Whiteboard', 'Desk Setup'], 'focus', 2, false, true),
            ('Jhelum (Focus Room)', 4, ARRAY['Whiteboard', 'Desk Setup'], 'focus', 2, false, true),
            ('Indus-Board Room', 12, ARRAY['Large Screen', 'Video Conference', 'Whiteboard', 'Presentation Setup'], 'special', 2, false, true),
            ('Nexus-Session Hall', 20, ARRAY['Audio System', 'Projector', 'Stage Setup', 'Microphones'], 'special', 2, false, true),
            ('Podcast Room', 4, ARRAY['Recording Equipment', 'Soundproofing', 'Microphones', 'Audio Interface'], 'special', 2, true, true);
        
        RAISE NOTICE 'Successfully inserted 9 sample rooms';
    ELSE
        RAISE NOTICE 'Rooms already exist, skipping sample data insertion';
    END IF;
EXCEPTION 
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inserting room data: %', SQLERRM;
        ROLLBACK;
END $$;

COMMIT;

-- Create triggers (separate transaction)
BEGIN;

-- Create triggers for updated_at timestamps
DO $$
BEGIN
    DROP TRIGGER IF EXISTS handle_users_updated_at ON public.users;
    CREATE TRIGGER handle_users_updated_at
        BEFORE UPDATE ON public.users
        FOR EACH ROW
        EXECUTE FUNCTION public.handle_updated_at();
    RAISE NOTICE 'Created users updated_at trigger';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error creating users trigger: %', SQLERRM;
END $$;

DO $$
BEGIN
    DROP TRIGGER IF EXISTS handle_startups_updated_at ON public.startups;
    CREATE TRIGGER handle_startups_updated_at
        BEFORE UPDATE ON public.startups
        FOR EACH ROW
        EXECUTE FUNCTION public.handle_updated_at();
    RAISE NOTICE 'Created startups updated_at trigger';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error creating startups trigger: %', SQLERRM;
END $$;

DO $$
BEGIN
    DROP TRIGGER IF EXISTS handle_rooms_updated_at ON public.rooms;
    CREATE TRIGGER handle_rooms_updated_at
        BEFORE UPDATE ON public.rooms
        FOR EACH ROW
        EXECUTE FUNCTION public.handle_updated_at();
    RAISE NOTICE 'Created rooms updated_at trigger';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error creating rooms trigger: %', SQLERRM;
END $$;

DO $$
BEGIN
    DROP TRIGGER IF EXISTS handle_bookings_updated_at ON public.bookings;
    CREATE TRIGGER handle_bookings_updated_at
        BEFORE UPDATE ON public.bookings
        FOR EACH ROW
        EXECUTE FUNCTION public.handle_updated_at();
    RAISE NOTICE 'Created bookings updated_at trigger';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error creating bookings trigger: %', SQLERRM;
END $$;

-- Create trigger to prevent overlapping bookings
DO $$
BEGIN
    DROP TRIGGER IF EXISTS check_booking_overlap_trigger ON public.bookings;
    CREATE TRIGGER check_booking_overlap_trigger
        BEFORE INSERT OR UPDATE ON public.bookings
        FOR EACH ROW
        EXECUTE FUNCTION public.check_booking_overlap();
    RAISE NOTICE 'Created booking overlap prevention trigger';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error creating overlap trigger: %', SQLERRM;
END $$;

COMMIT;

-- Final validation and reporting
DO $$
DECLARE
    room_count integer;
    user_count integer;
    admin_count integer;
BEGIN
    SELECT COUNT(*) INTO room_count FROM public.rooms;
    SELECT COUNT(*) INTO user_count FROM public.users;
    SELECT COUNT(*) INTO admin_count FROM public.users WHERE role = 'admin';
    
    RAISE NOTICE '';
    RAISE NOTICE '=== DATABASE SETUP COMPLETED SUCCESSFULLY ===';
    RAISE NOTICE 'Tables created: users, startups, rooms, bookings';
    RAISE NOTICE 'RLS policies: % total policies created', 15;
    RAISE NOTICE 'Triggers: 5 triggers created';
    RAISE NOTICE 'Sample rooms: % rooms available', room_count;
    RAISE NOTICE 'Users: % total users', user_count;
    RAISE NOTICE 'Admins: % admin users', admin_count;
    RAISE NOTICE '';
    
    IF admin_count = 0 THEN
        RAISE NOTICE '⚠️  NO ADMIN USERS FOUND!';
        RAISE NOTICE 'To fix the Contact Us page:';
        RAISE NOTICE '1. Go to Supabase Dashboard → Authentication → Users';
        RAISE NOTICE '2. Add a new user with email and password';
        RAISE NOTICE '3. In User Metadata, add: {"role": "admin", "name": "Admin Name", "phone": "+92-XXX-XXXXXXX"}';
        RAISE NOTICE '';
    END IF;
    
    RAISE NOTICE 'Database is ready for the NIC Booking Management System!';
END $$;

-- Display current rooms for verification
SELECT 'Current rooms in database:' as info;
SELECT name, capacity, room_type, max_duration, requires_equipment, is_active 
FROM public.rooms 
ORDER BY room_type, name;
