-- FIX 2: Update Room Capacities in Database
-- This script updates the capacity for Nexus-Session Hall and Indus-Board Room

-- Update Nexus-Session Hall capacity from 20 to 50
UPDATE public.rooms
SET capacity = 50,
    updated_at = NOW()
WHERE name = 'Nexus-Session Hall';

-- Update Indus-Board Room capacity from 12 to 25
UPDATE public.rooms
SET capacity = 25,
    updated_at = NOW()
WHERE name = 'Indus-Board Room';

-- Verify the updates
SELECT name, capacity, max_duration, room_type
FROM public.rooms
WHERE name IN ('Nexus-Session Hall', 'Indus-Board Room', 'Podcast Room')
ORDER BY name;

-- Expected results:
-- Indus-Board Room: capacity = 25, max_duration = 8
-- Nexus-Session Hall: capacity = 50, max_duration = 8
-- Podcast Room: capacity = 4, max_duration = 8

