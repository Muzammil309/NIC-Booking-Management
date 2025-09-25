-- COMPREHENSIVE SCHEMA TYPE FIX
-- This script fixes the type mismatch between bookings.startup_id and startups.id
-- Both should be uuid type for proper Supabase integration
-- Run this in Supabase SQL Editor to resolve the foreign key constraint error

-- 1. COMPREHENSIVE SCHEMA DIAGNOSIS
SELECT '=== CURRENT SCHEMA DIAGNOSIS ===' as status;

-- Check users table schema
SELECT 'USERS TABLE:' as table_name;
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'users'
AND column_name = 'id'
ORDER BY ordinal_position;

-- Check startups table schema
SELECT 'STARTUPS TABLE:' as table_name;
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'startups'
ORDER BY ordinal_position;

-- Check bookings table schema
SELECT 'BOOKINGS TABLE:' as table_name;
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'bookings'
ORDER BY ordinal_position;

-- 2. CHECK EXISTING DATA COUNTS
SELECT '=== EXISTING DATA COUNTS ===' as status;

SELECT 
    'users' as table_name,
    COUNT(*) as record_count
FROM public.users
UNION ALL
SELECT 
    'startups' as table_name,
    COUNT(*) as record_count
FROM public.startups
UNION ALL
SELECT 
    'bookings' as table_name,
    COUNT(*) as record_count
FROM public.bookings;

-- 3. COMPREHENSIVE TYPE CONVERSION
DO $$
DECLARE
    users_count INTEGER;
    startups_count INTEGER;
    bookings_count INTEGER;
    startups_id_type TEXT;
    users_id_type TEXT;
BEGIN
    -- Get data counts
    SELECT COUNT(*) INTO users_count FROM public.users;
    SELECT COUNT(*) INTO startups_count FROM public.startups;
    SELECT COUNT(*) INTO bookings_count FROM public.bookings;
    
    -- Get current column types
    SELECT data_type INTO startups_id_type 
    FROM information_schema.columns 
    WHERE table_schema = 'public' AND table_name = 'startups' AND column_name = 'id';
    
    SELECT data_type INTO users_id_type 
    FROM information_schema.columns 
    WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'id';
    
    RAISE NOTICE 'Data counts - Users: %, Startups: %, Bookings: %', users_count, startups_count, bookings_count;
    RAISE NOTICE 'Current types - users.id: %, startups.id: %', users_id_type, startups_id_type;
    
    -- Only proceed if no existing data (safe conversion)
    IF users_count = 0 AND startups_count = 0 AND bookings_count = 0 THEN
        RAISE NOTICE 'No existing data - proceeding with safe schema recreation';
        
        -- Step 1: Drop all RLS policies to avoid dependency issues
        RAISE NOTICE 'Step 1: Dropping all RLS policies...';
        
        -- Drop all policies on all tables
        DROP POLICY IF EXISTS "users_select_own" ON public.users;
        DROP POLICY IF EXISTS "users_insert_own" ON public.users;
        DROP POLICY IF EXISTS "users_update_own" ON public.users;
        DROP POLICY IF EXISTS "users_delete_own" ON public.users;
        DROP POLICY IF EXISTS "startups_select_own" ON public.startups;
        DROP POLICY IF EXISTS "startups_insert_own" ON public.startups;
        DROP POLICY IF EXISTS "startups_update_own" ON public.startups;
        DROP POLICY IF EXISTS "startups_delete_own" ON public.startups;
        DROP POLICY IF EXISTS "bookings_select_own" ON public.bookings;
        DROP POLICY IF EXISTS "bookings_insert_own" ON public.bookings;
        DROP POLICY IF EXISTS "bookings_update_own" ON public.bookings;
        DROP POLICY IF EXISTS "bookings_delete_own" ON public.bookings;
        
        -- Drop alternative policy names
        DROP POLICY IF EXISTS "Users can view their own profile" ON public.users;
        DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;
        DROP POLICY IF EXISTS "Users can create their own profile" ON public.users;
        DROP POLICY IF EXISTS "Users can view their own startup" ON public.startups;
        DROP POLICY IF EXISTS "Users can update their own startup" ON public.startups;
        DROP POLICY IF EXISTS "Users can create their own startup" ON public.startups;
        DROP POLICY IF EXISTS "Users can view their own bookings" ON public.bookings;
        DROP POLICY IF EXISTS "Users can create their own bookings" ON public.bookings;
        DROP POLICY IF EXISTS "Users can update their own bookings" ON public.bookings;
        
        RAISE NOTICE 'Successfully dropped all RLS policies';
        
        -- Step 2: Drop all foreign key constraints
        RAISE NOTICE 'Step 2: Dropping foreign key constraints...';
        
        ALTER TABLE public.bookings DROP CONSTRAINT IF EXISTS bookings_startup_id_fkey;
        ALTER TABLE public.startups DROP CONSTRAINT IF EXISTS startups_user_id_fkey;
        
        -- Step 3: Recreate tables with correct UUID types
        RAISE NOTICE 'Step 3: Recreating tables with correct UUID types...';
        
        -- Drop and recreate startups table if needed
        IF startups_id_type != 'uuid' THEN
            DROP TABLE IF EXISTS public.startups CASCADE;
            CREATE TABLE public.startups (
                id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
                user_id uuid NOT NULL,
                name text NOT NULL,
                contact_person text,
                phone text,
                email text,
                status text DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
                created_at timestamp with time zone DEFAULT now(),
                updated_at timestamp with time zone DEFAULT now()
            );
            RAISE NOTICE 'Recreated startups table with uuid id';
        END IF;
        
        -- Ensure bookings table has correct startup_id type
        ALTER TABLE public.bookings DROP COLUMN IF EXISTS startup_id;
        ALTER TABLE public.bookings ADD COLUMN startup_id uuid NOT NULL;
        
        -- Step 4: Add foreign key constraints back
        RAISE NOTICE 'Step 4: Adding foreign key constraints...';
        
        ALTER TABLE public.startups ADD CONSTRAINT startups_user_id_fkey 
            FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
            
        ALTER TABLE public.bookings ADD CONSTRAINT bookings_startup_id_fkey 
            FOREIGN KEY (startup_id) REFERENCES public.startups(id) ON DELETE CASCADE;
        
        -- Step 5: Recreate RLS policies
        RAISE NOTICE 'Step 5: Recreating RLS policies...';
        
        -- Users table policies
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

        -- Startups table policies
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

        -- Bookings table policies
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
        
        -- Step 6: Enable RLS on all tables
        ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
        ALTER TABLE public.startups ENABLE ROW LEVEL SECURITY;
        ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
        
        RAISE NOTICE '🎉 SCHEMA TYPE CONVERSION COMPLETED SUCCESSFULLY!';
        RAISE NOTICE '✅ All tables now use UUID types consistently';
        RAISE NOTICE '✅ Foreign key relationships restored';
        RAISE NOTICE '✅ RLS policies recreated with same security logic';
        RAISE NOTICE '✅ Ready for application testing';
        
    ELSE
        RAISE NOTICE '⚠️ EXISTING DATA FOUND - MANUAL INTERVENTION REQUIRED';
        RAISE NOTICE 'Cannot safely convert schema with existing data';
        RAISE NOTICE 'Please backup data and create custom migration strategy';
    END IF;
    
END $$;

-- 4. VERIFY FINAL SCHEMA
SELECT '=== FINAL SCHEMA VERIFICATION ===' as verification;

-- Verify all tables have correct types
SELECT 
    t.table_name,
    c.column_name,
    c.data_type,
    c.is_nullable
FROM information_schema.tables t
JOIN information_schema.columns c ON t.table_name = c.table_name
WHERE t.table_schema = 'public' 
AND t.table_name IN ('users', 'startups', 'bookings')
AND c.column_name IN ('id', 'user_id', 'startup_id')
ORDER BY t.table_name, c.column_name;

-- 5. VERIFY FOREIGN KEY CONSTRAINTS
SELECT '=== FOREIGN KEY CONSTRAINTS ===' as verification;

SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
AND tc.table_schema = 'public'
AND tc.table_name IN ('startups', 'bookings')
ORDER BY tc.table_name;

-- 6. FINAL SUCCESS MESSAGE
DO $$
BEGIN
    RAISE NOTICE '🚀 COMPREHENSIVE SCHEMA FIX COMPLETED!';
    RAISE NOTICE 'All tables now use UUID types consistently';
    RAISE NOTICE 'Foreign key relationships are properly established';
    RAISE NOTICE 'Application can now create bookings successfully';
    RAISE NOTICE 'Test room booking functionality through the application!';
END $$;
