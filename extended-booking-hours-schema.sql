-- ===== EXTENDED BOOKING HOURS FOR SPECIFIC ROOMS =====
-- This script updates the database to support extended booking hours for specific rooms

-- 1. Add extended_hours column to rooms table
ALTER TABLE public.rooms 
ADD COLUMN IF NOT EXISTS extended_hours BOOLEAN DEFAULT FALSE;

-- 2. Add max_booking_duration column to rooms table (in hours)
ALTER TABLE public.rooms 
ADD COLUMN IF NOT EXISTS max_booking_duration INTEGER DEFAULT 3;

-- 3. Update specific rooms to have extended hours and longer duration
UPDATE public.rooms 
SET 
    extended_hours = TRUE,
    max_booking_duration = 8
WHERE name IN ('Indus Board', 'Podcast Room', 'Nexus Session Hall');

-- 4. Create function to check if room has extended hours
CREATE OR REPLACE FUNCTION public.room_has_extended_hours(room_name_param TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM public.rooms 
        WHERE name = room_name_param 
        AND extended_hours = TRUE
    );
END;
$$;

-- 5. Create function to get room max booking duration
CREATE OR REPLACE FUNCTION public.get_room_max_duration(room_name_param TEXT)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    max_duration INTEGER;
BEGIN
    SELECT max_booking_duration 
    INTO max_duration
    FROM public.rooms 
    WHERE name = room_name_param;
    
    RETURN COALESCE(max_duration, 3); -- Default to 3 hours if not found
END;
$$;

-- 6. Create function to validate booking time constraints
CREATE OR REPLACE FUNCTION public.validate_booking_constraints(
    room_name_param TEXT,
    booking_date_param DATE,
    start_time_param TIME,
    duration_param INTEGER
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    room_extended_hours BOOLEAN;
    room_max_duration INTEGER;
    end_time TIME;
    result JSONB;
BEGIN
    -- Get room constraints
    SELECT extended_hours, max_booking_duration
    INTO room_extended_hours, room_max_duration
    FROM public.rooms
    WHERE name = room_name_param;
    
    -- Default values if room not found
    room_extended_hours := COALESCE(room_extended_hours, FALSE);
    room_max_duration := COALESCE(room_max_duration, 3);
    
    -- Calculate end time
    end_time := start_time_param + (duration_param || ' hours')::INTERVAL;
    
    -- Initialize result
    result := jsonb_build_object(
        'valid', true,
        'errors', '[]'::jsonb
    );
    
    -- Check duration constraint
    IF duration_param > room_max_duration THEN
        result := jsonb_set(
            result,
            '{valid}',
            'false'::jsonb
        );
        result := jsonb_set(
            result,
            '{errors}',
            result->'errors' || jsonb_build_array(
                'Duration exceeds maximum allowed for this room (' || room_max_duration || ' hours)'
            )
        );
    END IF;
    
    -- Check time constraints for non-extended hours rooms
    IF NOT room_extended_hours THEN
        -- Standard hours: 9 AM to 6 PM
        IF start_time_param < '09:00'::TIME OR start_time_param >= '18:00'::TIME THEN
            result := jsonb_set(
                result,
                '{valid}',
                'false'::jsonb
            );
            result := jsonb_set(
                result,
                '{errors}',
                result->'errors' || jsonb_build_array(
                    'Booking must be between 9:00 AM and 6:00 PM for this room'
                )
            );
        END IF;
        
        -- Check if booking extends beyond 6 PM
        IF end_time > '18:00'::TIME THEN
            result := jsonb_set(
                result,
                '{valid}',
                'false'::jsonb
            );
            result := jsonb_set(
                result,
                '{errors}',
                result->'errors' || jsonb_build_array(
                    'Booking cannot extend beyond 6:00 PM for this room'
                )
            );
        END IF;
    END IF;
    
    -- Check for overlapping bookings
    IF EXISTS (
        SELECT 1 
        FROM public.bookings 
        WHERE room_name = room_name_param 
        AND booking_date = booking_date_param
        AND status != 'cancelled'
        AND (
            (start_time <= start_time_param AND end_time > start_time_param) OR
            (start_time < end_time AND end_time > start_time_param) OR
            (start_time_param <= start_time AND end_time <= end_time)
        )
    ) THEN
        result := jsonb_set(
            result,
            '{valid}',
            'false'::jsonb
        );
        result := jsonb_set(
            result,
            '{errors}',
            result->'errors' || jsonb_build_array(
                'Time slot conflicts with existing booking'
            )
        );
    END IF;
    
    RETURN result;
END;
$$;

-- 7. Update RLS policies to work with new columns
-- (The existing policies should automatically work with the new columns)

-- 8. Grant necessary permissions
GRANT EXECUTE ON FUNCTION public.room_has_extended_hours(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_room_max_duration(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.validate_booking_constraints(TEXT, DATE, TIME, INTEGER) TO authenticated;

-- 9. Insert sample data if rooms don't exist
INSERT INTO public.rooms (name, capacity, room_type, extended_hours, max_booking_duration, requires_equipment)
VALUES 
    ('Indus Board', 12, 'Conference Room', TRUE, 8, FALSE),
    ('Podcast Room', 4, 'Media Room', TRUE, 8, TRUE),
    ('Nexus Session Hall', 50, 'Event Hall', TRUE, 8, FALSE)
ON CONFLICT (name) DO UPDATE SET
    extended_hours = EXCLUDED.extended_hours,
    max_booking_duration = EXCLUDED.max_booking_duration;

-- 10. Verification queries
SELECT 
    name,
    capacity,
    room_type,
    extended_hours,
    max_booking_duration,
    requires_equipment
FROM public.rooms
ORDER BY name;

-- Test the functions
SELECT 
    name,
    public.room_has_extended_hours(name) as has_extended_hours,
    public.get_room_max_duration(name) as max_duration
FROM public.rooms
ORDER BY name;

-- Test validation function
SELECT public.validate_booking_constraints(
    'Indus Board',
    CURRENT_DATE,
    '22:00'::TIME,
    6
) as validation_result;

SELECT public.validate_booking_constraints(
    'Hingol',
    CURRENT_DATE,
    '22:00'::TIME,
    6
) as validation_result;
