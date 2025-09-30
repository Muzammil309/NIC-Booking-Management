-- ===== FIX BROKEN ADMIN ACCOUNT: jawad@nic.com =====
-- This script fixes the jawad@nic.com account that was created with broken code
-- The auth user exists but the database user record is missing

-- STEP 1: Verify the issue
-- Check if auth user exists but database record is missing
DO $$
DECLARE
    auth_user_id UUID;
    db_user_exists BOOLEAN;
BEGIN
    -- Try to find the auth user ID
    -- Note: We can't directly query auth.users from SQL, so we'll check the users table
    
    RAISE NOTICE '=== DIAGNOSTIC CHECK ===';
    RAISE NOTICE 'Checking for jawad@nic.com in public.users table...';
    
    SELECT EXISTS (
        SELECT 1 FROM public.users WHERE email = 'jawad@nic.com'
    ) INTO db_user_exists;
    
    IF db_user_exists THEN
        RAISE NOTICE '✓ User record EXISTS in public.users table';
        RAISE NOTICE 'The account should be working. If not, check:';
        RAISE NOTICE '  1. Password is correct';
        RAISE NOTICE '  2. Email confirmation status in Supabase Dashboard';
        RAISE NOTICE '  3. Browser console for errors';
    ELSE
        RAISE NOTICE '✗ User record MISSING from public.users table';
        RAISE NOTICE 'This confirms the issue - auth user exists but no database record';
        RAISE NOTICE 'Proceed with STEP 2 to fix this';
    END IF;
END $$;

-- STEP 2: Get the auth user ID
-- You need to get this from Supabase Dashboard → Authentication → Users
-- Find jawad@nic.com and copy the User UID
-- It will look like: a1b2c3d4-e5f6-7890-abcd-ef1234567890

-- STEP 3: Insert the missing user record
-- IMPORTANT: Replace 'YOUR_AUTH_USER_ID_HERE' with the actual UUID from Step 2

-- UNCOMMENT AND RUN THIS AFTER GETTING THE UUID:
/*
INSERT INTO public.users (id, email, name, role, phone, created_at)
VALUES (
    'YOUR_AUTH_USER_ID_HERE',  -- ⚠️ REPLACE THIS with UUID from Supabase Dashboard
    'jawad@nic.com',
    'Jawad Ahmad',
    'admin',
    NULL,  -- Phone number (can be added later via Edit button)
    NOW()
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    name = EXCLUDED.name,
    role = EXCLUDED.role;
*/

-- STEP 4: Verify the fix
-- Run this after inserting the user record
SELECT 
    id,
    email,
    name,
    role,
    phone,
    created_at
FROM public.users
WHERE email = 'jawad@nic.com';

-- Expected result: One row showing the user details

-- STEP 5: Verify admin contacts for Contact Us page
SELECT 
    id,
    name,
    email,
    phone,
    role
FROM public.users
WHERE role = 'admin'
ORDER BY name;

-- Expected result: Should show all admin users including jawad@nic.com

-- ===== ALTERNATIVE: DELETE AND RECREATE =====
-- If you prefer to delete the broken auth user and recreate it with the fixed code

-- STEP A: Delete from public.users (if exists)
-- DELETE FROM public.users WHERE email = 'jawad@nic.com';

-- STEP B: Delete from auth.users
-- This must be done via Supabase Dashboard:
-- 1. Go to Authentication → Users
-- 2. Find jawad@nic.com
-- 3. Click three dots (...) → Delete user
-- 4. Confirm deletion

-- STEP C: Recreate using the fixed "Create Admin Account" button
-- 1. Login to NIC Booking app as admin
-- 2. Go to Startups tab
-- 3. Click "Create Admin Account" button
-- 4. Enter: jawad@nic.com, password, name, phone
-- 5. Done! The account will work correctly

-- ===== TROUBLESHOOTING =====

-- Check if there are any duplicate entries
SELECT email, COUNT(*) as count
FROM public.users
WHERE email = 'jawad@nic.com'
GROUP BY email;

-- Check all admin users
SELECT 
    id,
    email,
    name,
    role,
    created_at
FROM public.users
WHERE role = 'admin'
ORDER BY created_at DESC;

-- ===== NOTES =====
-- 1. The UUID in public.users.id MUST match the UUID in auth.users
-- 2. You can only get the auth.users UUID from Supabase Dashboard
-- 3. If you can't find the UUID, use the DELETE AND RECREATE method instead
-- 4. After fixing, the user should appear in Contact Us tab immediately
-- 5. The user should be able to login with their email and password

