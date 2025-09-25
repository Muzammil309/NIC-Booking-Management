-- SCHEMA VERIFICATION AND FIX SCRIPT
-- Run this BEFORE ultimate-fix-all-errors.sql to ensure all columns exist
-- This script will verify and fix any schema mismatches

-- 1. VERIFY CURRENT ROOMS TABLE SCHEMA
SELECT 'Current rooms table schema:' as info;

SELECT 
    column_name, 
    data_type, 
    column_default, 
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'rooms'
ORDER BY ordinal_position;

-- 2. CHECK FOR MISSING COLUMNS IN ROOMS TABLE
SELECT 'Checking for missing columns in rooms table...' as info;

SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'rooms' AND column_name = 'capacity')
        THEN '✅ capacity column EXISTS'
        ELSE '❌ capacity column MISSING'
    END as capacity_check,
    
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'rooms' AND column_name = 'equipment')
        THEN '✅ equipment column EXISTS'
        ELSE '❌ equipment column MISSING'
    END as equipment_check,
    
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'rooms' AND column_name = 'room_type')
        THEN '✅ room_type column EXISTS'
        ELSE '❌ room_type column MISSING'
    END as room_type_check,
    
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'rooms' AND column_name = 'max_duration')
        THEN '✅ max_duration column EXISTS'
        ELSE '❌ max_duration column MISSING'
    END as max_duration_check,
    
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'rooms' AND column_name = 'requires_equipment')
        THEN '✅ requires_equipment column EXISTS'
        ELSE '❌ requires_equipment column MISSING'
    END as requires_equipment_check,
    
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'rooms' AND column_name = 'is_active')
        THEN '✅ is_active column EXISTS'
        ELSE '❌ is_active column MISSING'
    END as is_active_check;

-- 3. ADD MISSING COLUMNS TO ROOMS TABLE
DO $$
BEGIN
    RAISE NOTICE 'Starting rooms table schema fix...';
    
    -- Add capacity column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'rooms' AND column_name = 'capacity'
    ) THEN
        ALTER TABLE public.rooms ADD COLUMN capacity integer DEFAULT 4;
        RAISE NOTICE '✅ Added capacity column to rooms table';
    ELSE
        RAISE NOTICE '✅ Capacity column already exists';
    END IF;

    -- Add equipment column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'rooms' AND column_name = 'equipment'
    ) THEN
        ALTER TABLE public.rooms ADD COLUMN equipment text[] DEFAULT '{}';
        RAISE NOTICE '✅ Added equipment column to rooms table';
    ELSE
        RAISE NOTICE '✅ Equipment column already exists';
    END IF;

    -- Add room_type column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'rooms' AND column_name = 'room_type'
    ) THEN
        ALTER TABLE public.rooms ADD COLUMN room_type text DEFAULT 'focus';
        RAISE NOTICE '✅ Added room_type column to rooms table';
    ELSE
        RAISE NOTICE '✅ Room_type column already exists';
    END IF;

    -- Add max_duration column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'rooms' AND column_name = 'max_duration'
    ) THEN
        ALTER TABLE public.rooms ADD COLUMN max_duration integer DEFAULT 2;
        RAISE NOTICE '✅ Added max_duration column to rooms table';
    ELSE
        RAISE NOTICE '✅ Max_duration column already exists';
    END IF;

    -- Add requires_equipment column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'rooms' AND column_name = 'requires_equipment'
    ) THEN
        ALTER TABLE public.rooms ADD COLUMN requires_equipment boolean DEFAULT false;
        RAISE NOTICE '✅ Added requires_equipment column to rooms table';
    ELSE
        RAISE NOTICE '✅ Requires_equipment column already exists';
    END IF;

    -- Add is_active column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'rooms' AND column_name = 'is_active'
    ) THEN
        ALTER TABLE public.rooms ADD COLUMN is_active boolean DEFAULT true;
        RAISE NOTICE '✅ Added is_active column to rooms table';
    ELSE
        RAISE NOTICE '✅ Is_active column already exists';
    END IF;

    RAISE NOTICE 'Rooms table schema fix completed!';
END $$;

-- 4. VERIFY SCHEMA IS NOW COMPLETE
SELECT 'Final verification - all required columns should exist:' as info;

SELECT 
    column_name, 
    data_type, 
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'rooms'
AND column_name IN ('name', 'capacity', 'equipment', 'room_type', 'max_duration', 'requires_equipment', 'is_active')
ORDER BY 
    CASE column_name
        WHEN 'name' THEN 1
        WHEN 'capacity' THEN 2
        WHEN 'equipment' THEN 3
        WHEN 'room_type' THEN 4
        WHEN 'max_duration' THEN 5
        WHEN 'requires_equipment' THEN 6
        WHEN 'is_active' THEN 7
    END;

-- 5. TEST INSERT STATEMENT (DRY RUN)
SELECT 'Testing INSERT statement compatibility...' as info;

-- This will show if the INSERT would work
SELECT 
    'name' as column_name, 'text' as expected_type,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'rooms' AND column_name = 'name') 
         THEN '✅ Compatible' ELSE '❌ Missing' END as status
UNION ALL
SELECT 
    'capacity', 'integer',
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'rooms' AND column_name = 'capacity') 
         THEN '✅ Compatible' ELSE '❌ Missing' END
UNION ALL
SELECT 
    'room_type', 'text',
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'rooms' AND column_name = 'room_type') 
         THEN '✅ Compatible' ELSE '❌ Missing' END
UNION ALL
SELECT 
    'max_duration', 'integer',
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'rooms' AND column_name = 'max_duration') 
         THEN '✅ Compatible' ELSE '❌ Missing' END
UNION ALL
SELECT 
    'requires_equipment', 'boolean',
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'rooms' AND column_name = 'requires_equipment') 
         THEN '✅ Compatible' ELSE '❌ Missing' END
UNION ALL
SELECT 
    'is_active', 'boolean',
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'rooms' AND column_name = 'is_active') 
         THEN '✅ Compatible' ELSE '❌ Missing' END;

SELECT '🎉 Schema verification and fix completed! You can now run ultimate-fix-all-errors.sql safely.' as final_message;
