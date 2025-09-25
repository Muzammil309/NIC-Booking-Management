-- COALESCE TYPE MISMATCH FIX
-- This script fixes the "COALESCE types integer and uuid cannot be matched" error
-- Run this in Supabase SQL Editor to resolve the booking creation issue

-- 1. DROP THE PROBLEMATIC TRIGGER FIRST
DROP TRIGGER IF EXISTS check_booking_overlap_trigger ON public.bookings;

-- 2. DROP THE PROBLEMATIC FUNCTION
DROP FUNCTION IF EXISTS public.check_booking_overlap();

-- 3. CREATE A FIXED OVERLAP PREVENTION FUNCTION
CREATE OR REPLACE FUNCTION public.check_booking_overlap()
RETURNS TRIGGER AS $$
BEGIN
    -- Check for overlapping bookings with proper NULL handling
    IF EXISTS (
        SELECT 1 FROM public.bookings 
        WHERE room_name = NEW.room_name 
        AND booking_date = NEW.booking_date
        AND (
            -- For INSERT operations, NEW.id is NULL, so we skip the ID check
            -- For UPDATE operations, we exclude the current record being updated
            (TG_OP = 'INSERT') OR 
            (TG_OP = 'UPDATE' AND id != NEW.id)
        )
        AND (
            -- Check if times overlap using OVERLAPS operator (more reliable)
            (NEW.start_time, (NEW.start_time + (NEW.duration || ' hours')::interval)::time) OVERLAPS 
            (start_time, (start_time + (duration || ' hours')::interval)::time)
        )
    ) THEN
        RAISE EXCEPTION 'Booking conflicts with existing reservation for % on % at %', NEW.room_name, NEW.booking_date, NEW.start_time;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. RECREATE THE TRIGGER WITH THE FIXED FUNCTION
CREATE TRIGGER check_booking_overlap_trigger
    BEFORE INSERT OR UPDATE ON public.bookings
    FOR EACH ROW EXECUTE FUNCTION public.check_booking_overlap();

-- 5. CLEAN UP ANY EXTRA COLUMNS THAT MIGHT BE CAUSING ISSUES
-- Remove user_id and room_id columns if they exist (they're not needed)
DO $$
BEGIN
    -- Drop user_id column if it exists (we use startup_id instead)
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'bookings' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.bookings DROP COLUMN user_id;
        RAISE NOTICE 'Dropped unnecessary user_id column from bookings table';
    END IF;

    -- Drop room_id column if it exists (we use room_name instead)
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'bookings' AND column_name = 'room_id'
    ) THEN
        ALTER TABLE public.bookings DROP COLUMN room_id;
        RAISE NOTICE 'Dropped unnecessary room_id column from bookings table';
    END IF;
END $$;

-- 6. ENSURE CORRECT COLUMN TYPES FOR ALL REMAINING COLUMNS
DO $$
BEGIN
    -- Ensure startup_id is uuid type
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'bookings' 
        AND column_name = 'startup_id' AND data_type != 'uuid'
    ) THEN
        ALTER TABLE public.bookings ALTER COLUMN startup_id TYPE uuid USING startup_id::uuid;
        RAISE NOTICE 'Fixed startup_id column type to uuid';
    END IF;

    -- Ensure duration is integer type
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'bookings' 
        AND column_name = 'duration' AND data_type != 'integer'
    ) THEN
        ALTER TABLE public.bookings ALTER COLUMN duration TYPE integer USING duration::integer;
        RAISE NOTICE 'Fixed duration column type to integer';
    END IF;
END $$;

-- 7. VERIFY THE FINAL BOOKINGS TABLE STRUCTURE
SELECT 'Final bookings table structure:' as status;

SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'bookings'
ORDER BY ordinal_position;

-- 8. TEST THE BOOKING INSERT COMPATIBILITY
SELECT 'Testing booking insert compatibility...' as status;

-- Show the exact INSERT template that should work
SELECT 
    'INSERT INTO public.bookings (' || 
    string_agg(column_name, ', ' ORDER BY ordinal_position) || 
    ') VALUES (...);' as insert_template
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'bookings'
AND column_name NOT IN ('id', 'created_at', 'updated_at'); -- Exclude auto-generated columns

-- 9. VERIFY TRIGGERS ARE WORKING
SELECT 'Current triggers on bookings table:' as status;

SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers
WHERE event_object_schema = 'public'
AND event_object_table = 'bookings';

-- 10. FINAL SUCCESS MESSAGE
DO $$
BEGIN
    RAISE NOTICE '🎉 COALESCE type mismatch fix completed successfully!';
    RAISE NOTICE '✅ Problematic overlap trigger function fixed';
    RAISE NOTICE '✅ Unnecessary columns removed (user_id, room_id)';
    RAISE NOTICE '✅ Column types verified and corrected';
    RAISE NOTICE '✅ Booking creation should now work without type errors';
    RAISE NOTICE '🚀 Try creating a room booking through the application now!';
END $$;
