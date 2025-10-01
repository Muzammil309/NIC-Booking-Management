-- ============================================================================
-- FIX ALL THREE ISSUES - COMPREHENSIVE SQL SCRIPT
-- ============================================================================
-- This script fixes:
-- 1. Admin account creation (RLS policies for users table)
-- 2. Room capacities verification and update
-- 3. Room status management verification
-- ============================================================================

-- ============================================================================
-- PART 1: FIX ADMIN ACCOUNT CREATION (ISSUE 1)
-- ============================================================================

-- Ensure the helper function exists
CREATE OR REPLACE FUNCTION public.is_current_user_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid() AND role = 'admin'
    );
$$;

-- Drop existing policies on users table if they exist
DROP POLICY IF EXISTS users_insert_admin ON public.users;
DROP POLICY IF EXISTS users_select_all ON public.users;
DROP POLICY IF EXISTS users_update_admin ON public.users;
DROP POLICY IF EXISTS users_delete_admin ON public.users;

-- Create policy to allow admins to INSERT (create) new users
CREATE POLICY users_insert_admin ON public.users
FOR INSERT
WITH CHECK (
    -- Allow if current user is admin
    public.is_current_user_admin()
    OR
    -- Allow if user is creating their own profile (during signup)
    id = auth.uid()
);

-- Create policy to allow everyone to SELECT their own user data
-- and admins to SELECT all users
CREATE POLICY users_select_all ON public.users
FOR SELECT
USING (
    -- Allow if user is viewing their own data
    id = auth.uid()
    OR
    -- Allow if current user is admin
    public.is_current_user_admin()
);

-- Create policy to allow admins to UPDATE any user
CREATE POLICY users_update_admin ON public.users
FOR UPDATE
USING (
    -- Allow if user is updating their own data
    id = auth.uid()
    OR
    -- Allow if current user is admin
    public.is_current_user_admin()
)
WITH CHECK (
    -- Allow if user is updating their own data
    id = auth.uid()
    OR
    -- Allow if current user is admin
    public.is_current_user_admin()
);

-- Create policy to allow admins to DELETE users
CREATE POLICY users_delete_admin ON public.users
FOR DELETE
USING (
    -- Allow if current user is admin
    public.is_current_user_admin()
);

-- ============================================================================
-- PART 2: VERIFY AND FIX ROOM CAPACITIES (ISSUE 2)
-- ============================================================================

-- First, check current room capacities
SELECT 
    name, 
    capacity, 
    max_duration,
    room_type,
    status
FROM public.rooms
WHERE name IN ('Nexus-Session Hall', 'Indus-Board Room', 'Podcast Room')
ORDER BY name;

-- Update room capacities to correct values
UPDATE public.rooms
SET 
    capacity = 50,
    updated_at = NOW()
WHERE name = 'Nexus-Session Hall';

UPDATE public.rooms
SET 
    capacity = 25,
    updated_at = NOW()
WHERE name = 'Indus-Board Room';

-- Verify the updates
SELECT 
    name, 
    capacity, 
    max_duration,
    room_type,
    status,
    updated_at
FROM public.rooms
WHERE name IN ('Nexus-Session Hall', 'Indus-Board Room', 'Podcast Room')
ORDER BY name;

-- ============================================================================
-- PART 3: VERIFY ROOM STATUS MANAGEMENT (ISSUE 3)
-- ============================================================================

-- Check current room statuses
SELECT 
    r.id,
    r.name,
    r.status AS room_status,
    r.capacity,
    rd.current_status AS display_status,
    rd.status_message,
    rd.last_updated
FROM public.rooms r
LEFT JOIN public.room_displays rd ON rd.room_id = r.id
ORDER BY r.name;

-- Ensure all rooms have a default status if NULL
UPDATE public.rooms
SET status = 'available'
WHERE status IS NULL;

-- Verify room_displays table has correct room_id references
SELECT 
    rd.id AS display_id,
    rd.room_id,
    r.name AS room_name,
    rd.current_status,
    rd.is_enabled
FROM public.room_displays rd
LEFT JOIN public.rooms r ON r.id = rd.room_id
ORDER BY r.name;

-- ============================================================================
-- PART 4: VERIFY RLS POLICIES
-- ============================================================================

-- Check all RLS policies on users table
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'users'
ORDER BY policyname;

-- Check all RLS policies on startups table
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'startups'
ORDER BY policyname;

-- Check all RLS policies on rooms table
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'rooms'
ORDER BY policyname;

-- ============================================================================
-- PART 5: TEST QUERIES
-- ============================================================================

-- Test if current user is admin
SELECT public.is_current_user_admin() AS is_admin;

-- Test if current user can see users table
SELECT COUNT(*) AS user_count FROM public.users;

-- Test if current user can see rooms table
SELECT COUNT(*) AS room_count FROM public.rooms;

-- ============================================================================
-- EXPECTED RESULTS
-- ============================================================================
-- 1. Helper function created/updated: is_current_user_admin()
-- 2. Four new policies created on users table:
--    - users_insert_admin (allows admins to create users)
--    - users_select_all (allows users to see their own data, admins to see all)
--    - users_update_admin (allows admins to update any user)
--    - users_delete_admin (allows admins to delete users)
-- 3. Room capacities updated:
--    - Nexus-Session Hall: 50
--    - Indus-Board Room: 25
-- 4. All rooms have a status (default: 'available')
-- 5. Test queries return expected results for admin users
-- ============================================================================

-- ============================================================================
-- TROUBLESHOOTING
-- ============================================================================
-- If admin creation still fails with "User not allowed":
-- 1. Verify you're logged in as an admin user
-- 2. Check that is_current_user_admin() returns true
-- 3. Verify the users_insert_admin policy exists
-- 4. Check Supabase logs for detailed error messages
--
-- If room capacities still show old values:
-- 1. Verify the UPDATE queries above succeeded
-- 2. Check that the rooms table has the correct values
-- 3. Clear browser cache and hard refresh (Ctrl+Shift+R)
-- 4. Check browser console for any JavaScript errors
--
-- If room status not working:
-- 1. Verify room_displays table has correct room_id references
-- 2. Check that rooms table has status column
-- 3. Verify RLS policies allow reading/updating rooms table
-- ============================================================================

