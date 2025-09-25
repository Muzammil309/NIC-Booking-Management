-- SCHEMA CACHE AND TRIGGER FIX
-- This script fixes the room booking schema cache error and startup profile update trigger error
-- Run this in Supabase SQL Editor to resolve both critical issues

-- 1. VERIFY AND FIX BOOKINGS TABLE SCHEMA
SELECT 'Checking bookings table schema...' as status;

-- Check current bookings table structure
SELECT 
    column_name, 
    data_type, 
    column_default, 
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'bookings'
ORDER BY ordinal_position;

-- 2. ENSURE ALL REQUIRED COLUMNS EXIST IN BOOKINGS TABLE
DO $$
BEGIN
    RAISE NOTICE 'Ensuring all required columns exist in bookings table...';
    
    -- Add room_name column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'bookings' AND column_name = 'room_name'
    ) THEN
        ALTER TABLE public.bookings ADD COLUMN room_name text NOT NULL;
        RAISE NOTICE 'Added room_name column to bookings table';
    ELSE
        RAISE NOTICE 'room_name column already exists in bookings table';
    END IF;

    -- Add startup_id column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'bookings' AND column_name = 'startup_id'
    ) THEN
        ALTER TABLE public.bookings ADD COLUMN startup_id uuid REFERENCES public.startups(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added startup_id column to bookings table';
    ELSE
        RAISE NOTICE 'startup_id column already exists in bookings table';
    END IF;

    -- Add booking_date column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'bookings' AND column_name = 'booking_date'
    ) THEN
        ALTER TABLE public.bookings ADD COLUMN booking_date date NOT NULL;
        RAISE NOTICE 'Added booking_date column to bookings table';
    ELSE
        RAISE NOTICE 'booking_date column already exists in bookings table';
    END IF;

    -- Add start_time column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'bookings' AND column_name = 'start_time'
    ) THEN
        ALTER TABLE public.bookings ADD COLUMN start_time time NOT NULL;
        RAISE NOTICE 'Added start_time column to bookings table';
    ELSE
        RAISE NOTICE 'start_time column already exists in bookings table';
    END IF;

    -- Add duration column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'bookings' AND column_name = 'duration'
    ) THEN
        ALTER TABLE public.bookings ADD COLUMN duration integer NOT NULL DEFAULT 1 CHECK (duration > 0 AND duration <= 8);
        RAISE NOTICE 'Added duration column to bookings table';
    ELSE
        RAISE NOTICE 'duration column already exists in bookings table';
    END IF;

    -- Add equipment_notes column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'bookings' AND column_name = 'equipment_notes'
    ) THEN
        ALTER TABLE public.bookings ADD COLUMN equipment_notes text;
        RAISE NOTICE 'Added equipment_notes column to bookings table';
    ELSE
        RAISE NOTICE 'equipment_notes column already exists in bookings table';
    END IF;

    -- Add is_confidential column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'bookings' AND column_name = 'is_confidential'
    ) THEN
        ALTER TABLE public.bookings ADD COLUMN is_confidential boolean DEFAULT false;
        RAISE NOTICE 'Added is_confidential column to bookings table';
    ELSE
        RAISE NOTICE 'is_confidential column already exists in bookings table';
    END IF;

    -- Add status column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'bookings' AND column_name = 'status'
    ) THEN
        ALTER TABLE public.bookings ADD COLUMN status text DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'cancelled', 'completed'));
        RAISE NOTICE 'Added status column to bookings table';
    ELSE
        RAISE NOTICE 'status column already exists in bookings table';
    END IF;

    -- Add room_type column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'bookings' AND column_name = 'room_type'
    ) THEN
        ALTER TABLE public.bookings ADD COLUMN room_type text;
        RAISE NOTICE 'Added room_type column to bookings table';
    ELSE
        RAISE NOTICE 'room_type column already exists in bookings table';
    END IF;

    -- Add created_at column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'bookings' AND column_name = 'created_at'
    ) THEN
        ALTER TABLE public.bookings ADD COLUMN created_at timestamp with time zone DEFAULT now();
        RAISE NOTICE 'Added created_at column to bookings table';
    ELSE
        RAISE NOTICE 'created_at column already exists in bookings table';
    END IF;

    -- Add updated_at column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'bookings' AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE public.bookings ADD COLUMN updated_at timestamp with time zone DEFAULT now();
        RAISE NOTICE 'Added updated_at column to bookings table';
    ELSE
        RAISE NOTICE 'updated_at column already exists in bookings table';
    END IF;
END $$;

-- 3. ENSURE STARTUPS TABLE HAS UPDATED_AT COLUMN
DO $$
BEGIN
    -- Add updated_at column to startups if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'startups' AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE public.startups ADD COLUMN updated_at timestamp with time zone DEFAULT now();
        RAISE NOTICE 'Added updated_at column to startups table';
    ELSE
        RAISE NOTICE 'updated_at column already exists in startups table';
    END IF;
END $$;

-- 4. CREATE OR REPLACE UPDATED_AT TRIGGER FUNCTION
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 5. CREATE UPDATED_AT TRIGGERS FOR ALL TABLES
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON public.users 
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_startups_updated_at ON public.startups;
CREATE TRIGGER update_startups_updated_at 
    BEFORE UPDATE ON public.startups 
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_bookings_updated_at ON public.bookings;
CREATE TRIGGER update_bookings_updated_at 
    BEFORE UPDATE ON public.bookings 
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_rooms_updated_at ON public.rooms;
CREATE TRIGGER update_rooms_updated_at 
    BEFORE UPDATE ON public.rooms 
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- 6. REFRESH SCHEMA CACHE (Force Supabase to recognize changes)
-- This helps resolve schema cache issues
NOTIFY pgrst, 'reload schema';

-- 7. VERIFICATION QUERIES
SELECT 'Bookings table verification:' as status;

SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'bookings'
AND column_name IN ('room_name', 'startup_id', 'booking_date', 'start_time', 'duration', 'equipment_notes', 'is_confidential', 'status', 'room_type', 'created_at', 'updated_at')
ORDER BY 
    CASE column_name
        WHEN 'room_name' THEN 1
        WHEN 'startup_id' THEN 2
        WHEN 'booking_date' THEN 3
        WHEN 'start_time' THEN 4
        WHEN 'duration' THEN 5
        WHEN 'equipment_notes' THEN 6
        WHEN 'is_confidential' THEN 7
        WHEN 'status' THEN 8
        WHEN 'room_type' THEN 9
        WHEN 'created_at' THEN 10
        WHEN 'updated_at' THEN 11
    END;

-- 8. TEST BOOKING INSERT (DRY RUN)
SELECT 'Testing booking insert compatibility...' as status;

-- This shows what columns are available for INSERT
SELECT 
    'INSERT INTO public.bookings (' || string_agg(column_name, ', ' ORDER BY ordinal_position) || ') VALUES (...);' as insert_template
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'bookings'
AND column_name != 'id';

-- 9. FINAL SUCCESS MESSAGE
DO $$
BEGIN
    RAISE NOTICE '🎉 Schema cache and trigger fixes completed successfully!';
    RAISE NOTICE '✅ Bookings table schema verified and updated';
    RAISE NOTICE '✅ All required columns exist for room booking';
    RAISE NOTICE '✅ Updated_at triggers created for all tables';
    RAISE NOTICE '✅ Schema cache refresh triggered';
    RAISE NOTICE '🚀 Room booking and profile updates should now work!';
END $$;
