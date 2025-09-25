-- CONSTRAINT FIX AND REAL ROOMS SETUP
-- This script specifically handles check constraint issues and sets up actual NIC facility rooms
-- Run this BEFORE ultimate-fix-all-errors.sql if you continue to have constraint issues

-- 1. DROP ALL EXISTING CHECK CONSTRAINTS ON ROOMS TABLE
DO $$
DECLARE
    constraint_record RECORD;
BEGIN
    RAISE NOTICE 'Dropping all existing check constraints on rooms table...';
    
    -- Find and drop all check constraints on rooms table
    FOR constraint_record IN 
        SELECT conname 
        FROM pg_constraint 
        WHERE conrelid = (
            SELECT oid FROM pg_class 
            WHERE relname = 'rooms' AND relnamespace = (
                SELECT oid FROM pg_namespace WHERE nspname = 'public'
            )
        )
        AND contype = 'c'
    LOOP
        BEGIN
            EXECUTE format('ALTER TABLE public.rooms DROP CONSTRAINT IF EXISTS %I', constraint_record.conname);
            RAISE NOTICE 'Dropped constraint: %', constraint_record.conname;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Could not drop constraint %: %', constraint_record.conname, SQLERRM;
        END;
    END LOOP;
    
    RAISE NOTICE 'Finished dropping existing constraints';
END $$;

-- 2. ENSURE ALL REQUIRED COLUMNS EXIST
DO $$
BEGIN
    -- Add room_type column without constraint first
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'rooms' AND column_name = 'room_type'
    ) THEN
        ALTER TABLE public.rooms ADD COLUMN room_type text DEFAULT 'focus';
        RAISE NOTICE 'Added room_type column';
    END IF;

    -- Add capacity column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'rooms' AND column_name = 'capacity'
    ) THEN
        ALTER TABLE public.rooms ADD COLUMN capacity integer DEFAULT 4;
        RAISE NOTICE 'Added capacity column';
    END IF;

    -- Add max_duration column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'rooms' AND column_name = 'max_duration'
    ) THEN
        ALTER TABLE public.rooms ADD COLUMN max_duration integer DEFAULT 2;
        RAISE NOTICE 'Added max_duration column';
    END IF;

    -- Add requires_equipment column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'rooms' AND column_name = 'requires_equipment'
    ) THEN
        ALTER TABLE public.rooms ADD COLUMN requires_equipment boolean DEFAULT false;
        RAISE NOTICE 'Added requires_equipment column';
    END IF;

    -- Add is_active column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'rooms' AND column_name = 'is_active'
    ) THEN
        ALTER TABLE public.rooms ADD COLUMN is_active boolean DEFAULT true;
        RAISE NOTICE 'Added is_active column';
    END IF;

    -- Add equipment column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'rooms' AND column_name = 'equipment'
    ) THEN
        ALTER TABLE public.rooms ADD COLUMN equipment text[] DEFAULT '{}';
        RAISE NOTICE 'Added equipment column';
    END IF;
END $$;

-- 3. UPDATE ANY EXISTING INVALID ROOM_TYPE VALUES
UPDATE public.rooms 
SET room_type = 'focus' 
WHERE room_type IS NULL OR room_type NOT IN ('focus', 'special', 'hub', 'board', 'session', 'podcast');

-- 4. ADD COMPREHENSIVE ROOM_TYPE CHECK CONSTRAINT
ALTER TABLE public.rooms 
ADD CONSTRAINT rooms_comprehensive_room_type_check 
CHECK (room_type IN ('focus', 'special', 'hub', 'board', 'session', 'podcast'));

-- 5. INSERT ACTUAL NIC FACILITY ROOMS
INSERT INTO public.rooms (name, capacity, room_type, max_duration, requires_equipment, is_active, equipment)
VALUES 
    -- Hub Rooms (collaborative spaces for team work)
    ('Hub Room 1', 6, 'hub', 3, false, true, ARRAY['Whiteboard', 'TV Display', 'Conference Phone']),
    ('Hub Room 2', 6, 'hub', 3, false, true, ARRAY['Whiteboard', 'TV Display', 'Conference Phone']),
    ('Hub Room 3', 6, 'hub', 3, false, true, ARRAY['Whiteboard', 'TV Display', 'Conference Phone']),
    
    -- Named Conference/Meeting Rooms
    ('Hingol', 8, 'board', 4, false, true, ARRAY['Large Conference Table', 'Projector', 'Audio System']),
    ('Telenor Velocity', 10, 'board', 4, true, true, ARRAY['Smart Board', 'Video Conferencing', 'Presentation System']),
    ('Sutlej', 6, 'focus', 3, false, true, ARRAY['Meeting Table', 'TV Display']),
    ('Chenab', 6, 'focus', 3, false, true, ARRAY['Meeting Table', 'TV Display']),
    ('Jhelum', 6, 'focus', 3, false, true, ARRAY['Meeting Table', 'TV Display']),
    
    -- Board and Session Rooms (large capacity)
    ('Indus Board', 12, 'board', 6, true, true, ARRAY['Boardroom Table', 'Projector', 'Audio/Video System', 'Conference Phone']),
    ('Nexus Session Hall', 20, 'session', 8, true, true, ARRAY['Auditorium Seating', 'Stage', 'Sound System', 'Lighting', 'Projection']),
    
    -- Specialized Equipment Rooms
    ('Podcast Room', 4, 'podcast', 2, true, true, ARRAY['Recording Equipment', 'Soundproofing', 'Microphones', 'Audio Interface', 'Editing Station'])
ON CONFLICT (name) DO UPDATE SET
    capacity = EXCLUDED.capacity,
    room_type = EXCLUDED.room_type,
    max_duration = EXCLUDED.max_duration,
    requires_equipment = EXCLUDED.requires_equipment,
    is_active = EXCLUDED.is_active,
    equipment = EXCLUDED.equipment;

-- 6. VERIFICATION
SELECT 'Room setup verification:' as status;

SELECT 
    name,
    capacity,
    room_type,
    max_duration,
    requires_equipment,
    is_active,
    array_length(equipment, 1) as equipment_count
FROM public.rooms
ORDER BY 
    CASE room_type
        WHEN 'hub' THEN 1
        WHEN 'focus' THEN 2
        WHEN 'board' THEN 3
        WHEN 'session' THEN 4
        WHEN 'podcast' THEN 5
    END,
    name;

-- 7. CHECK CONSTRAINT VERIFICATION
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'public.rooms'::regclass 
AND contype = 'c';

RAISE NOTICE 'NIC facility rooms setup completed successfully!';
RAISE NOTICE 'Room types supported: hub, focus, board, session, podcast';
RAISE NOTICE 'Total rooms configured: %', (SELECT COUNT(*) FROM public.rooms);
