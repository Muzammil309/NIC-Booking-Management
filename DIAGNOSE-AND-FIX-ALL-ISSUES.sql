-- ============================================================================
-- DIAGNOSE AND FIX ALL THREE ISSUES - ENHANCED SQL SCRIPT
-- ============================================================================
-- This script:
-- 1. Diagnoses room capacity issue (checks actual database values)
-- 2. Fixes room status dropdown (adds RLS policies for rooms table)
-- 3. Fixes admin booking cancellation (adds RLS policies for bookings table)
-- ============================================================================

-- ============================================================================
-- PART 1: DIAGNOSE ROOM CAPACITIES ISSUE (ISSUE 1)
-- ============================================================================

-- Step 1: Check if rooms table exists and has data
SELECT 
    'Checking rooms table...' AS step,
    COUNT(*) AS total_rooms
FROM public.rooms;

-- Step 2: Check CURRENT capacity values in database
SELECT 
    'CURRENT DATABASE VALUES' AS step,
    name, 
    capacity, 
    max_duration,
    room_type,
    status,
    updated_at
FROM public.rooms
WHERE name IN ('Nexus-Session Hall', 'Indus-Board Room', 'Podcast Room')
ORDER BY name;

-- Step 3: If values are WRONG (20 and 12), update them
-- Run these UPDATE queries:

UPDATE public.rooms
SET 
    capacity = 50,
    max_duration = 8,
    updated_at = NOW()
WHERE name = 'Nexus-Session Hall';

UPDATE public.rooms
SET 
    capacity = 25,
    max_duration = 8,
    updated_at = NOW()
WHERE name = 'Indus-Board Room';

-- Step 4: Verify the updates worked
SELECT 
    'AFTER UPDATE - VERIFY' AS step,
    name, 
    capacity, 
    max_duration,
    room_type,
    status,
    updated_at
FROM public.rooms
WHERE name IN ('Nexus-Session Hall', 'Indus-Board Room', 'Podcast Room')
ORDER BY name;

-- Step 5: Check ALL rooms to see if there are duplicates
SELECT 
    'ALL ROOMS IN DATABASE' AS step,
    id,
    name, 
    capacity, 
    max_duration,
    room_type,
    status
FROM public.rooms
ORDER BY name;

-- ============================================================================
-- PART 2: FIX ROOM STATUS DROPDOWN (ISSUE 2)
-- ============================================================================

-- Step 1: Check current RLS policies on rooms table
SELECT 
    'CURRENT RLS POLICIES ON ROOMS TABLE' AS step,
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'rooms'
ORDER BY policyname;

-- Step 2: Drop existing policies if they exist
DROP POLICY IF EXISTS rooms_select_all ON public.rooms;
DROP POLICY IF EXISTS rooms_update_admin ON public.rooms;
DROP POLICY IF EXISTS rooms_insert_admin ON public.rooms;
DROP POLICY IF EXISTS rooms_delete_admin ON public.rooms;

-- Step 3: Create policy to allow everyone to SELECT rooms
CREATE POLICY rooms_select_all ON public.rooms
FOR SELECT
USING (true);  -- Allow everyone to read rooms

-- Step 4: Create policy to allow admins to UPDATE rooms
CREATE POLICY rooms_update_admin ON public.rooms
FOR UPDATE
USING (
    -- Allow if current user is admin
    public.is_current_user_admin()
)
WITH CHECK (
    -- Allow if current user is admin
    public.is_current_user_admin()
);

-- Step 5: Create policy to allow admins to INSERT rooms
CREATE POLICY rooms_insert_admin ON public.rooms
FOR INSERT
WITH CHECK (
    -- Allow if current user is admin
    public.is_current_user_admin()
);

-- Step 6: Create policy to allow admins to DELETE rooms
CREATE POLICY rooms_delete_admin ON public.rooms
FOR DELETE
USING (
    -- Allow if current user is admin
    public.is_current_user_admin()
);

-- Step 7: Verify policies were created
SELECT 
    'NEW RLS POLICIES ON ROOMS TABLE' AS step,
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'rooms'
ORDER BY policyname;

-- ============================================================================
-- PART 3: FIX ADMIN BOOKING CANCELLATION (ISSUE 3)
-- ============================================================================

-- Step 1: Check current RLS policies on bookings table
SELECT 
    'CURRENT RLS POLICIES ON BOOKINGS TABLE' AS step,
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'bookings'
ORDER BY policyname;

-- Step 2: Drop existing DELETE policy if it exists
DROP POLICY IF EXISTS bookings_delete_admin ON public.bookings;
DROP POLICY IF EXISTS bookings_delete_own ON public.bookings;

-- Step 3: Create policy to allow admins to DELETE any booking
CREATE POLICY bookings_delete_admin ON public.bookings
FOR DELETE
USING (
    -- Allow if current user is admin
    public.is_current_user_admin()
    OR
    -- Allow if user is deleting their own booking
    startup_id IN (
        SELECT id FROM public.startups WHERE user_id = auth.uid()
    )
);

-- Step 4: Verify policy was created
SELECT 
    'NEW RLS POLICIES ON BOOKINGS TABLE' AS step,
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'bookings'
ORDER BY policyname;

-- ============================================================================
-- PART 4: COMPREHENSIVE VERIFICATION
-- ============================================================================

-- Test 1: Verify helper function works
SELECT 
    'TEST: Is current user admin?' AS test,
    public.is_current_user_admin() AS is_admin;

-- Test 2: Verify room capacities are correct
SELECT 
    'TEST: Room capacities' AS test,
    name,
    capacity,
    CASE 
        WHEN name = 'Nexus-Session Hall' AND capacity = 50 THEN '✅ CORRECT'
        WHEN name = 'Indus-Board Room' AND capacity = 25 THEN '✅ CORRECT'
        WHEN name = 'Podcast Room' AND capacity = 4 THEN '✅ CORRECT'
        ELSE '❌ WRONG'
    END AS status
FROM public.rooms
WHERE name IN ('Nexus-Session Hall', 'Indus-Board Room', 'Podcast Room')
ORDER BY name;

-- Test 3: Verify rooms table is accessible
SELECT 
    'TEST: Can read rooms table?' AS test,
    COUNT(*) AS room_count
FROM public.rooms;

-- Test 4: Verify bookings table is accessible
SELECT 
    'TEST: Can read bookings table?' AS test,
    COUNT(*) AS booking_count
FROM public.bookings;

-- Test 5: Check room_displays table
SELECT 
    'TEST: Room displays' AS test,
    rd.id,
    rd.room_id,
    r.name AS room_name,
    r.capacity AS room_capacity,
    rd.current_status,
    rd.is_enabled
FROM public.room_displays rd
LEFT JOIN public.rooms r ON r.id = rd.room_id
WHERE r.name IN ('Nexus-Session Hall', 'Indus-Board Room', 'Podcast Room')
ORDER BY r.name;

-- ============================================================================
-- EXPECTED RESULTS
-- ============================================================================
-- ISSUE 1 (Room Capacities):
--   - Nexus-Session Hall: capacity = 50 ✅
--   - Indus-Board Room: capacity = 25 ✅
--   - Podcast Room: capacity = 4 ✅
--
-- ISSUE 2 (Room Status Dropdown):
--   - 4 new policies created on rooms table:
--     * rooms_select_all (allows everyone to read)
--     * rooms_update_admin (allows admins to update)
--     * rooms_insert_admin (allows admins to insert)
--     * rooms_delete_admin (allows admins to delete)
--
-- ISSUE 3 (Admin Booking Cancellation):
--   - 1 new policy created on bookings table:
--     * bookings_delete_admin (allows admins to delete any booking)
--
-- All test queries should return expected results
-- ============================================================================

-- ============================================================================
-- TROUBLESHOOTING GUIDE
-- ============================================================================
-- 
-- ISSUE 1: Room capacities still show wrong values
-- ------------------------------------------------
-- Symptom: Console shows "capacity = 20" or "capacity = 12"
-- 
-- Diagnosis:
-- 1. Run: SELECT name, capacity FROM public.rooms WHERE name IN ('Nexus-Session Hall', 'Indus-Board Room');
-- 2. If shows 20 and 12, the UPDATE queries failed
-- 3. Check if there are multiple rows with same name (duplicates)
-- 
-- Solution:
-- 1. Check for duplicates: SELECT name, COUNT(*) FROM public.rooms GROUP BY name HAVING COUNT(*) > 1;
-- 2. If duplicates exist, delete old ones and keep the correct one
-- 3. Re-run UPDATE queries above
-- 4. Hard refresh browser (Ctrl+Shift+R)
-- 
-- ISSUE 2: Room status dropdown not working
-- ------------------------------------------
-- Symptom: Dropdown doesn't change status, no error messages
-- 
-- Diagnosis:
-- 1. Check browser console for errors
-- 2. Look for: "new row violates row-level security policy" (code 42501)
-- 3. Run: SELECT policyname FROM pg_policies WHERE tablename = 'rooms';
-- 
-- Solution:
-- 1. Verify rooms_update_admin policy exists
-- 2. Verify is_current_user_admin() returns true
-- 3. Re-run PART 2 of this script
-- 4. Hard refresh browser
-- 
-- ISSUE 3: Admin cannot cancel bookings
-- --------------------------------------
-- Symptom: No "Cancel Booking" button visible, or cancellation fails
-- 
-- Diagnosis:
-- 1. Check browser console for errors
-- 2. Look for RLS policy errors
-- 3. Run: SELECT policyname FROM pg_policies WHERE tablename = 'bookings';
-- 
-- Solution:
-- 1. Verify bookings_delete_admin policy exists
-- 2. Re-run PART 3 of this script
-- 3. Deploy updated code with "Cancel Booking" button
-- 4. Hard refresh browser
-- 
-- ============================================================================

