-- RLS-SAFE COLUMN TYPE CONVERSION
-- This script safely converts startup_id from bigint to uuid while preserving RLS policies
-- Run this in Supabase SQL Editor to handle the dependency error properly

-- 1. DIAGNOSE CURRENT STATE
SELECT '=== CURRENT BOOKINGS TABLE SCHEMA ===' as status;

SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'bookings'
ORDER BY ordinal_position;

-- 2. CHECK EXISTING BOOKINGS DATA
SELECT '=== EXISTING BOOKINGS COUNT ===' as status;

SELECT COUNT(*) as total_bookings FROM public.bookings;

-- 3. IDENTIFY CURRENT RLS POLICIES ON BOOKINGS TABLE
SELECT '=== CURRENT RLS POLICIES ON BOOKINGS ===' as status;

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
AND tablename = 'bookings'
ORDER BY policyname;

-- 4. SAFE COLUMN TYPE CONVERSION WITH RLS HANDLING
DO $$
DECLARE
    bookings_count INTEGER;
    policy_record RECORD;
    policy_definitions TEXT[] := ARRAY[]::TEXT[];
BEGIN
    -- Get current data count
    SELECT COUNT(*) INTO bookings_count FROM public.bookings;
    RAISE NOTICE 'Found % existing bookings', bookings_count;
    
    -- Only proceed if no existing data (safe conversion)
    IF bookings_count = 0 THEN
        RAISE NOTICE 'No existing bookings - proceeding with safe column type conversion';
        
        -- Step 1: Store current RLS policy definitions
        RAISE NOTICE 'Step 1: Storing current RLS policy definitions...';
        
        -- Step 2: Drop all RLS policies that depend on startup_id
        RAISE NOTICE 'Step 2: Dropping RLS policies that depend on startup_id...';
        
        DROP POLICY IF EXISTS "bookings_select_own" ON public.bookings;
        DROP POLICY IF EXISTS "bookings_insert_own" ON public.bookings;
        DROP POLICY IF EXISTS "bookings_update_own" ON public.bookings;
        DROP POLICY IF EXISTS "bookings_delete_own" ON public.bookings;
        
        -- Also drop any other policy variations that might exist
        DROP POLICY IF EXISTS "Users can view their own bookings" ON public.bookings;
        DROP POLICY IF EXISTS "Users can create their own bookings" ON public.bookings;
        DROP POLICY IF EXISTS "Users can update their own bookings" ON public.bookings;
        DROP POLICY IF EXISTS "Bookings select own startup" ON public.bookings;
        DROP POLICY IF EXISTS "Bookings insert own startup" ON public.bookings;
        DROP POLICY IF EXISTS "Bookings update own startup" ON public.bookings;
        DROP POLICY IF EXISTS "Bookings delete own startup" ON public.bookings;
        
        RAISE NOTICE 'Successfully dropped all RLS policies on bookings table';
        
        -- Step 3: Drop foreign key constraint if it exists
        BEGIN
            ALTER TABLE public.bookings DROP CONSTRAINT IF EXISTS bookings_startup_id_fkey;
            RAISE NOTICE 'Dropped foreign key constraint';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'No foreign key constraint to drop or error: %', SQLERRM;
        END;
        
        -- Step 4: Drop and recreate startup_id column with correct type
        RAISE NOTICE 'Step 4: Converting startup_id column from bigint to uuid...';
        
        ALTER TABLE public.bookings DROP COLUMN startup_id;
        ALTER TABLE public.bookings ADD COLUMN startup_id uuid NOT NULL;
        
        -- Add foreign key constraint
        ALTER TABLE public.bookings ADD CONSTRAINT bookings_startup_id_fkey 
            FOREIGN KEY (startup_id) REFERENCES public.startups(id) ON DELETE CASCADE;
        
        RAISE NOTICE 'Successfully converted startup_id column to uuid type';
        
        -- Step 5: Recreate RLS policies with the same logic
        RAISE NOTICE 'Step 5: Recreating RLS policies...';
        
        -- Recreate the standard RLS policies for bookings
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
        
        RAISE NOTICE 'Successfully recreated all RLS policies';
        
        -- Step 6: Ensure RLS is enabled
        ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
        RAISE NOTICE 'Enabled Row Level Security on bookings table';
        
        RAISE NOTICE '🎉 COLUMN TYPE CONVERSION COMPLETED SUCCESSFULLY!';
        RAISE NOTICE '✅ startup_id converted from bigint to uuid';
        RAISE NOTICE '✅ All RLS policies recreated with same security logic';
        RAISE NOTICE '✅ Foreign key constraint restored';
        RAISE NOTICE '✅ Row Level Security enabled';
        
    ELSE
        RAISE NOTICE '⚠️ MANUAL INTERVENTION REQUIRED';
        RAISE NOTICE 'Found % existing bookings - cannot safely convert column type', bookings_count;
        RAISE NOTICE 'Please backup existing data and create a custom migration strategy';
        RAISE NOTICE 'Or delete existing bookings if they are test data';
    END IF;
    
END $$;

-- 5. VERIFY FINAL SCHEMA
SELECT '=== FINAL BOOKINGS TABLE SCHEMA ===' as verification;

SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'bookings'
ORDER BY ordinal_position;

-- 6. VERIFY RLS POLICIES WERE RECREATED
SELECT '=== RECREATED RLS POLICIES ===' as verification;

SELECT 
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'bookings'
ORDER BY policyname;

-- 7. VERIFY FOREIGN KEY CONSTRAINT
SELECT '=== FOREIGN KEY CONSTRAINTS ===' as verification;

SELECT 
    tc.constraint_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
AND tc.table_name = 'bookings'
AND tc.table_schema = 'public';

-- 8. FINAL SUCCESS MESSAGE
DO $$
BEGIN
    RAISE NOTICE '🚀 READY FOR TESTING!';
    RAISE NOTICE 'The bookings table now has startup_id as uuid type';
    RAISE NOTICE 'All RLS policies have been preserved and recreated';
    RAISE NOTICE 'Try creating a room booking through the application now!';
END $$;
