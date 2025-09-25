-- SCHEMA DIAGNOSIS AND TYPE CONVERSION FIX
-- This script diagnoses the current schema and fixes the bigint to uuid conversion error
-- Run this in Supabase SQL Editor to properly handle the type conversion

-- 1. DIAGNOSE CURRENT SCHEMA STATE
SELECT '=== CURRENT BOOKINGS TABLE SCHEMA ===' as diagnosis;

SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'bookings'
ORDER BY ordinal_position;

-- 2. CHECK STARTUPS TABLE ID TYPE
SELECT '=== STARTUPS TABLE ID COLUMN TYPE ===' as diagnosis;

SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'startups'
AND column_name = 'id';

-- 3. CHECK EXISTING DATA IN BOOKINGS TABLE
SELECT '=== EXISTING BOOKINGS DATA COUNT ===' as diagnosis;

SELECT 
    COUNT(*) as total_bookings,
    COUNT(DISTINCT startup_id) as unique_startup_ids
FROM public.bookings;

-- 4. SAMPLE EXISTING DATA (if any)
SELECT '=== SAMPLE EXISTING BOOKINGS DATA ===' as diagnosis;

SELECT 
    id,
    startup_id,
    room_name,
    booking_date,
    start_time
FROM public.bookings 
LIMIT 5;

-- 5. CHECK FOREIGN KEY CONSTRAINTS
SELECT '=== FOREIGN KEY CONSTRAINTS ON BOOKINGS ===' as diagnosis;

SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
AND tc.table_name = 'bookings'
AND tc.table_schema = 'public';

-- 6. SAFE TYPE CONVERSION STRATEGY
DO $$
DECLARE
    bookings_count INTEGER;
    startups_id_type TEXT;
BEGIN
    -- Get current data count
    SELECT COUNT(*) INTO bookings_count FROM public.bookings;
    
    -- Get startups.id column type
    SELECT data_type INTO startups_id_type 
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'startups' 
    AND column_name = 'id';
    
    RAISE NOTICE 'Found % existing bookings', bookings_count;
    RAISE NOTICE 'Startups.id column type: %', startups_id_type;
    
    -- Strategy 1: If no existing bookings, safe to recreate column
    IF bookings_count = 0 THEN
        RAISE NOTICE 'No existing bookings - safe to recreate startup_id column';
        
        -- Drop foreign key constraint if it exists
        BEGIN
            ALTER TABLE public.bookings DROP CONSTRAINT IF EXISTS bookings_startup_id_fkey;
            RAISE NOTICE 'Dropped foreign key constraint';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'No foreign key constraint to drop';
        END;
        
        -- Drop and recreate startup_id column with correct type
        ALTER TABLE public.bookings DROP COLUMN IF EXISTS startup_id;
        ALTER TABLE public.bookings ADD COLUMN startup_id uuid REFERENCES public.startups(id) ON DELETE CASCADE NOT NULL;
        
        RAISE NOTICE 'Successfully recreated startup_id column as uuid type';
        
    -- Strategy 2: If there are existing bookings, need data migration
    ELSE
        RAISE NOTICE 'Found existing bookings - need data migration strategy';
        RAISE NOTICE 'Current startup_id values need to be mapped to uuid values';
        
        -- Check if startup_id values can be interpreted as valid data
        RAISE NOTICE 'Manual intervention required for data migration';
        RAISE NOTICE 'Please check the existing startup_id values and determine mapping strategy';
    END IF;
    
END $$;

-- 7. VERIFY FINAL SCHEMA (if conversion was successful)
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

-- 8. TEST INSERT COMPATIBILITY
SELECT '=== INSERT TEMPLATE FOR APPLICATION ===' as verification;

SELECT 
    'INSERT INTO public.bookings (' || 
    string_agg(column_name, ', ' ORDER BY ordinal_position) || 
    ') VALUES (...);' as insert_template
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'bookings'
AND column_name NOT IN ('id', 'created_at', 'updated_at');

-- 9. FINAL RECOMMENDATIONS
DO $$
BEGIN
    RAISE NOTICE '=== RECOMMENDATIONS ===';
    RAISE NOTICE '1. Check the diagnosis output above';
    RAISE NOTICE '2. If startup_id was successfully converted to uuid, test booking creation';
    RAISE NOTICE '3. If manual migration is needed, backup data first';
    RAISE NOTICE '4. Ensure application sends uuid values for startup_id';
    RAISE NOTICE '5. Verify foreign key relationship with startups table';
END $$;
