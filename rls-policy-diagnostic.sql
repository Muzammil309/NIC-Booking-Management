-- RLS POLICY DIAGNOSTIC SCRIPT
-- Run this in Supabase SQL Editor to check current policy status

-- Check all policies on users table
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
WHERE tablename = 'users' AND schemaname = 'public'
ORDER BY policyname;

-- Check all policies on startups table  
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
WHERE tablename = 'startups' AND schemaname = 'public'
ORDER BY policyname;

-- Check RLS status on tables
SELECT 
    schemaname,
    tablename,
    rowsecurity,
    forcerowsecurity
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('users', 'startups', 'rooms', 'bookings');

-- Test auth context (run this while logged in)
DO $$
BEGIN
    RAISE NOTICE 'Current auth.uid(): %', auth.uid();
    RAISE NOTICE 'Current auth.role(): %', auth.role();
    RAISE NOTICE 'Current auth.email(): %', auth.email();
    
    -- Check if we can see auth.users
    IF EXISTS (SELECT 1 FROM auth.users LIMIT 1) THEN
        RAISE NOTICE '✅ Can access auth.users table';
    ELSE
        RAISE NOTICE '❌ Cannot access auth.users table';
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error checking auth context: %', SQLERRM;
END $$;

-- Count existing profiles
SELECT 
    'users' as table_name,
    COUNT(*) as row_count
FROM public.users
UNION ALL
SELECT 
    'startups' as table_name,
    COUNT(*) as row_count  
FROM public.startups
UNION ALL
SELECT 
    'rooms' as table_name,
    COUNT(*) as row_count
FROM public.rooms
UNION ALL
SELECT 
    'bookings' as table_name,
    COUNT(*) as row_count
FROM public.bookings;
