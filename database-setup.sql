-- NIC Booking Management Database Setup
-- Run this SQL in your Supabase SQL Editor to ensure proper database structure
-- This script is safe to run multiple times

BEGIN;

-- Create rooms table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.rooms (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL UNIQUE,
    capacity integer DEFAULT 4,
    equipment text[] DEFAULT '{}',
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Enable RLS on rooms table
ALTER TABLE public.rooms ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Allow authenticated users to read rooms" ON public.rooms;
DROP POLICY IF EXISTS "Allow admins to manage rooms" ON public.rooms;

-- Create policy for rooms (allow all authenticated users to read)
CREATE POLICY "Allow authenticated users to read rooms" ON public.rooms
    FOR SELECT TO authenticated USING (true);

-- Create policy for admins to manage rooms
CREATE POLICY "Allow admins to manage rooms" ON public.rooms
    FOR ALL TO authenticated
    USING (auth.jwt() ->> 'role' = 'admin')
    WITH CHECK (auth.jwt() ->> 'role' = 'admin');

-- Insert sample rooms if none exist
INSERT INTO public.rooms (name, capacity, equipment, is_active)
SELECT * FROM (VALUES
    ('Conference Room A', 12, ARRAY['Projector', 'Whiteboard', 'Video Conference'], true),
    ('Meeting Room B', 6, ARRAY['TV Screen', 'Whiteboard'], true),
    ('Podcast Studio', 4, ARRAY['Recording Equipment', 'Soundproofing'], true),
    ('Collaboration Space', 8, ARRAY['Flipchart', 'Markers'], true),
    ('Private Office', 2, ARRAY['Desk', 'Chairs'], true)
) AS v(name, capacity, equipment, is_active)
WHERE NOT EXISTS (SELECT 1 FROM public.rooms);

-- Ensure users table has proper structure for admin contacts
-- (This assumes the users table already exists from authentication setup)

-- Create a function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for rooms table
DROP TRIGGER IF EXISTS handle_rooms_updated_at ON public.rooms;
CREATE TRIGGER handle_rooms_updated_at
    BEFORE UPDATE ON public.rooms
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

COMMIT;

-- Display setup results
DO $$
BEGIN
    RAISE NOTICE 'Database setup completed successfully!';
    RAISE NOTICE 'Rooms table: % rows', (SELECT COUNT(*) FROM public.rooms);
    RAISE NOTICE 'Admin users: % found', (SELECT COUNT(*) FROM public.users WHERE role = 'admin');
END $$;

-- Display current rooms
SELECT 'Current rooms in database:' as info;
SELECT id, name, capacity, equipment, is_active, created_at FROM public.rooms ORDER BY name;

-- Display admin users for contact verification
SELECT 'Current admin users for Contact Us page:' as info;
SELECT id, name, email, phone, role FROM public.users WHERE role = 'admin' ORDER BY name;

-- If no admin users found, show instructions
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.users WHERE role = 'admin') THEN
        RAISE NOTICE '';
        RAISE NOTICE '⚠️  NO ADMIN USERS FOUND!';
        RAISE NOTICE 'To fix the Contact Us page, create an admin user:';
        RAISE NOTICE '1. Go to Supabase Dashboard → Authentication → Users';
        RAISE NOTICE '2. Add a new user with email and password';
        RAISE NOTICE '3. In User Metadata, add: {"role": "admin", "name": "Admin Name", "phone": "+92-XXX-XXXXXXX"}';
        RAISE NOTICE '';
    END IF;
END $$;
