-- Set per-room maximum booking durations
-- Extended hours rooms: 8 hours; Standard rooms: 2 hours

-- 0) Safety: add required columns if they do not exist
ALTER TABLE public.rooms
  ADD COLUMN IF NOT EXISTS extended_hours BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS max_booking_duration INTEGER DEFAULT 2;

-- 1) Normalize extended-hours room names set (cover common naming variants)
--    Supports both "Nexus Session Hall" and "Nexus-Session Hall", and "Indus Board" and "Indus-Board Room"
WITH extended_names AS (
  SELECT unnest(ARRAY[
    'Indus Board',
    'Indus-Board Room',
    'Podcast Room',
    'Nexus Session Hall',
    'Nexus-Session Hall'
  ]) AS name
)
UPDATE public.rooms r
SET extended_hours = TRUE,
    max_booking_duration = 8
FROM extended_names e
WHERE r.name = e.name;

-- 2) Set all other rooms to 2-hour max (do not override explicit extended flags)
UPDATE public.rooms r
SET max_booking_duration = 2,
    extended_hours = COALESCE(extended_hours, FALSE)
WHERE NOT EXISTS (
  SELECT 1 FROM (VALUES
    ('Indus Board'),
    ('Indus-Board Room'),
    ('Podcast Room'),
    ('Nexus Session Hall'),
    ('Nexus-Session Hall')
  ) AS x(name)
  WHERE x.name = r.name
);

-- 3) Verify
SELECT name, extended_hours, max_booking_duration FROM public.rooms ORDER BY name;
