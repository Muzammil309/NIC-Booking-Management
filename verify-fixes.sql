-- VERIFICATION SCRIPT FOR ALL FIXES
-- Run this after ultimate-fix-all-errors.sql to verify everything works

-- 1. VERIFY SCHEMA STRUCTURE
SELECT 'Checking startups table schema...' as status;

SELECT 
    column_name, 
    data_type, 
    column_default, 
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'startups'
ORDER BY ordinal_position;

-- 2. VERIFY STATUS COLUMN EXISTS
SELECT 'Checking status column specifically...' as status;

SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'startups' 
            AND column_name = 'status'
        ) 
        THEN '✅ Status column EXISTS in startups table'
        ELSE '❌ Status column MISSING from startups table'
    END as status_column_check;

-- 3. VERIFY RLS POLICIES
SELECT 'Checking RLS policies...' as status;

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
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- 4. VERIFY ADMIN FUNCTION
SELECT 'Testing admin function...' as status;

SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_proc p
            JOIN pg_namespace n ON p.pronamespace = n.oid
            WHERE n.nspname = 'public'
            AND p.proname = 'is_admin'
        )
        THEN '✅ is_admin function EXISTS'
        ELSE '❌ is_admin function MISSING'
    END as admin_function_check;

-- 5. VERIFY TRIGGER EXISTS
SELECT 'Checking automatic profile creation trigger...' as status;

SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_timing,
    action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'auth'
AND trigger_name = 'on_auth_user_created';

-- 6. VERIFY ROOMS DATA
SELECT 'Checking rooms data...' as status;

SELECT 
    name,
    capacity,
    room_type,
    max_duration,
    status as room_status,
    is_active
FROM public.rooms
ORDER BY name;

-- 7. TEST ADMIN FUNCTION (if you have admin user)
SELECT 'Testing admin function with current user...' as status;

SELECT 
    auth.uid() as current_user_id,
    public.is_admin(auth.uid()) as is_current_user_admin;

-- 8. VERIFY RLS IS ENABLED
SELECT 'Checking RLS status...' as status;

SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public'
AND tablename IN ('users', 'startups', 'bookings', 'rooms')
ORDER BY tablename;

-- 9. COUNT POLICIES PER TABLE
SELECT 'Policy count per table...' as status;

SELECT 
    tablename,
    COUNT(*) as policy_count
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;

-- 10. FINAL STATUS CHECK
SELECT 'VERIFICATION COMPLETE' as status;

SELECT 
    CASE 
        WHEN (
            -- Check if status column exists
            EXISTS (
                SELECT 1 FROM information_schema.columns 
                WHERE table_schema = 'public' 
                AND table_name = 'startups' 
                AND column_name = 'status'
            )
            AND
            -- Check if admin function exists
            EXISTS (
                SELECT 1 FROM pg_proc p
                JOIN pg_namespace n ON p.pronamespace = n.oid
                WHERE n.nspname = 'public'
                AND p.proname = 'is_admin'
            )
            AND
            -- Check if policies exist
            EXISTS (
                SELECT 1 FROM pg_policies 
                WHERE schemaname = 'public'
            )
            AND
            -- Check if RLS is enabled
            (SELECT COUNT(*) FROM pg_tables 
             WHERE schemaname = 'public'
             AND tablename IN ('users', 'startups', 'bookings', 'rooms')
             AND rowsecurity = true) = 4
        )
        THEN '🎉 ALL FIXES VERIFIED SUCCESSFULLY! 🎉'
        ELSE '⚠️ Some issues may still exist. Check individual results above.'
    END as final_verification_result;
