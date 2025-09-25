-- TEST SCRIPT FOR RLS POLICIES AND PROFILE CREATION
-- Run this in Supabase SQL Editor AFTER running comprehensive-rls-fix.sql
-- This script will help diagnose any remaining issues

-- 1. CHECK RLS STATUS
SELECT 
    schemaname,
    tablename,
    rowsecurity as "RLS Enabled"
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('users', 'startups', 'bookings', 'rooms')
ORDER BY tablename;

-- 2. COUNT RLS POLICIES
SELECT 
    tablename,
    COUNT(*) as "Policy Count"
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;

-- 3. LIST ALL POLICIES
SELECT 
    tablename,
    policyname,
    cmd as "Command",
    permissive,
    roles
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- 4. CHECK TRIGGER EXISTENCE
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE trigger_schema = 'auth' 
AND event_object_table = 'users'
AND trigger_name = 'on_auth_user_created';

-- 5. CHECK FUNCTION EXISTENCE
SELECT 
    routine_name,
    routine_type,
    security_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name = 'handle_new_user';

-- 6. TEST CURRENT USER CONTEXT (if logged in)
SELECT 
    auth.uid() as "Current User ID",
    auth.role() as "Current Role",
    CASE 
        WHEN auth.uid() IS NOT NULL THEN 'Authenticated'
        ELSE 'Anonymous'
    END as "Auth Status";

-- 7. COUNT EXISTING DATA
SELECT 'users' as table_name, COUNT(*) as record_count FROM public.users
UNION ALL
SELECT 'startups' as table_name, COUNT(*) as record_count FROM public.startups
UNION ALL
SELECT 'bookings' as table_name, COUNT(*) as record_count FROM public.bookings
UNION ALL
SELECT 'rooms' as table_name, COUNT(*) as record_count FROM public.rooms
ORDER BY table_name;

-- 8. CHECK FOR ORPHANED RECORDS
SELECT 
    'Startups without users' as issue,
    COUNT(*) as count
FROM public.startups s
LEFT JOIN public.users u ON s.user_id = u.id
WHERE u.id IS NULL

UNION ALL

SELECT 
    'Bookings without startups' as issue,
    COUNT(*) as count
FROM public.bookings b
LEFT JOIN public.startups s ON b.startup_id = s.id
WHERE s.id IS NULL

UNION ALL

SELECT 
    'Users without startups (role=startup)' as issue,
    COUNT(*) as count
FROM public.users u
LEFT JOIN public.startups s ON u.id = s.user_id
WHERE u.role = 'startup' AND s.id IS NULL;

-- 9. SAMPLE DATA CHECK (if any exists)
DO $$
DECLARE
    user_count INTEGER;
    startup_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO user_count FROM public.users;
    SELECT COUNT(*) INTO startup_count FROM public.startups;
    
    RAISE NOTICE '';
    RAISE NOTICE '=== DIAGNOSTIC SUMMARY ===';
    RAISE NOTICE 'Users in database: %', user_count;
    RAISE NOTICE 'Startups in database: %', startup_count;
    
    IF user_count = 0 THEN
        RAISE NOTICE 'No users found - this is normal for a fresh installation';
    END IF;
    
    IF startup_count = 0 AND user_count > 0 THEN
        RAISE NOTICE 'WARNING: Users exist but no startups found';
        RAISE NOTICE 'This might indicate profile creation issues';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '=== NEXT STEPS ===';
    RAISE NOTICE '1. If RLS policies show 0 count, re-run comprehensive-rls-fix.sql';
    RAISE NOTICE '2. If trigger is missing, re-run comprehensive-rls-fix.sql';
    RAISE NOTICE '3. Test signup with a new user to verify automatic profile creation';
    RAISE NOTICE '4. Test manual startup profile creation in Settings tab';
    RAISE NOTICE '5. Test room booking functionality';
    RAISE NOTICE '';
END $$;
