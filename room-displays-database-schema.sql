-- ROOM DISPLAYS DATABASE SCHEMA
-- This script adds the necessary database tables for room display management
-- Run this AFTER the nuclear-database-reset.sql script

-- ============================================================================
-- PHASE 1: CREATE ROOM DISPLAYS TABLES
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '🎨 Creating Room Displays Database Schema...';
END $$;

-- 1.1: Create display_content table for managing uploaded media
CREATE TABLE public.display_content (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL,
    description text,
    content_type text NOT NULL CHECK (content_type IN ('image', 'video', 'text', 'announcement')),
    file_url text, -- Supabase storage URL for images/videos
    text_content text, -- For text-based content
    file_size bigint, -- File size in bytes
    mime_type text, -- MIME type for uploaded files
    duration integer, -- Duration in seconds for videos
    created_by uuid REFERENCES public.users(id) ON DELETE SET NULL,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- 1.2: Create display_layouts table for different display templates
CREATE TABLE public.display_layouts (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL UNIQUE,
    description text,
    layout_config jsonb NOT NULL, -- JSON configuration for layout structure
    preview_image_url text, -- Preview image of the layout
    is_default boolean DEFAULT false,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- 1.3: Create room_displays table for room-specific display configurations
CREATE TABLE public.room_displays (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    room_id uuid REFERENCES public.rooms(id) ON DELETE CASCADE NOT NULL,
    layout_id uuid REFERENCES public.display_layouts(id) ON DELETE SET NULL,
    display_name text NOT NULL,
    is_enabled boolean DEFAULT true,
    current_status text DEFAULT 'available' CHECK (current_status IN ('available', 'occupied', 'maintenance', 'reserved')),
    status_message text,
    last_updated timestamp with time zone DEFAULT now(),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    UNIQUE(room_id)
);

-- 1.4: Create display_content_schedule table for content scheduling
CREATE TABLE public.display_content_schedule (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    room_display_id uuid REFERENCES public.room_displays(id) ON DELETE CASCADE NOT NULL,
    content_id uuid REFERENCES public.display_content(id) ON DELETE CASCADE NOT NULL,
    display_order integer DEFAULT 1,
    start_time time,
    end_time time,
    start_date date,
    end_date date,
    days_of_week text[], -- Array of days: ['monday', 'tuesday', etc.]
    duration_seconds integer DEFAULT 30, -- How long to show this content
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- 1.5: Create room_display_logs table for tracking display activity
CREATE TABLE public.room_display_logs (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    room_display_id uuid REFERENCES public.room_displays(id) ON DELETE CASCADE NOT NULL,
    action text NOT NULL, -- 'content_changed', 'status_updated', 'layout_changed'
    details jsonb,
    performed_by uuid REFERENCES public.users(id) ON DELETE SET NULL,
    created_at timestamp with time zone DEFAULT now()
);

-- ============================================================================
-- PHASE 2: CREATE STORAGE BUCKET POLICIES (for Supabase Storage)
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '📁 Setting up storage bucket policies...';
END $$;

-- Note: These policies need to be created in Supabase Storage UI or via API
-- Creating the bucket structure documentation here

/*
SUPABASE STORAGE BUCKET SETUP:
1. Create bucket named 'room-displays' in Supabase Storage
2. Set up the following folder structure:
   - room-displays/
     - images/
     - videos/
     - layouts/
     - announcements/

3. Set bucket policies:
   - Allow authenticated users to read all files
   - Allow admin users to upload/delete files
   - Set file size limits (e.g., 50MB for videos, 10MB for images)
*/

-- ============================================================================
-- PHASE 3: INSERT DEFAULT DISPLAY LAYOUTS
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '🎨 Inserting default display layouts...';
END $$;

-- Insert default display layouts
INSERT INTO public.display_layouts (name, description, layout_config, is_default) VALUES
(
    'Standard Room Display',
    'Default layout with room status, current booking, and announcements',
    '{
        "sections": [
            {
                "type": "header",
                "height": "20%",
                "content": ["room_name", "current_time", "status"]
            },
            {
                "type": "main",
                "height": "60%",
                "content": ["current_booking", "next_booking", "room_image"]
            },
            {
                "type": "footer",
                "height": "20%",
                "content": ["announcements", "qr_code"]
            }
        ],
        "colors": {
            "primary": "#2563eb",
            "secondary": "#64748b",
            "success": "#16a34a",
            "warning": "#d97706",
            "danger": "#dc2626"
        }
    }',
    true
),
(
    'Minimal Display',
    'Clean, minimal layout focusing on current status',
    '{
        "sections": [
            {
                "type": "full",
                "height": "100%",
                "content": ["room_name", "status", "current_booking"]
            }
        ],
        "colors": {
            "primary": "#1f2937",
            "secondary": "#6b7280",
            "success": "#059669",
            "warning": "#d97706",
            "danger": "#dc2626"
        }
    }',
    false
),
(
    'Media Rich Display',
    'Layout with prominent media content and rotating announcements',
    '{
        "sections": [
            {
                "type": "media",
                "height": "70%",
                "content": ["room_image", "video_content", "slideshow"]
            },
            {
                "type": "info",
                "height": "30%",
                "content": ["room_name", "status", "announcements"]
            }
        ],
        "colors": {
            "primary": "#7c3aed",
            "secondary": "#a78bfa",
            "success": "#10b981",
            "warning": "#f59e0b",
            "danger": "#ef4444"
        }
    }',
    false
);

-- ============================================================================
-- PHASE 4: CREATE ROOM DISPLAYS FOR EXISTING ROOMS
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '📺 Creating room displays for existing rooms...';
END $$;

-- Create room displays for all existing rooms
INSERT INTO public.room_displays (room_id, layout_id, display_name)
SELECT 
    r.id,
    (SELECT id FROM public.display_layouts WHERE is_default = true LIMIT 1),
    r.name || ' Display'
FROM public.rooms r
WHERE r.is_active = true;

-- ============================================================================
-- PHASE 5: CREATE SAMPLE DISPLAY CONTENT
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '📄 Creating sample display content...';
END $$;

-- Insert sample display content
INSERT INTO public.display_content (name, description, content_type, text_content, is_active) VALUES
(
    'Welcome Message',
    'General welcome message for all rooms',
    'text',
    'Welcome to NIC! Please ensure you have a confirmed booking before using this room.',
    true
),
(
    'Room Guidelines',
    'General room usage guidelines',
    'text',
    'Room Guidelines:\n• Keep the room clean\n• End meetings on time\n• Report any technical issues\n• Respect other users',
    true
),
(
    'Emergency Information',
    'Emergency contact and procedures',
    'announcement',
    'Emergency Contact: Security Desk - Ext. 911\nFire Assembly Point: Main Parking Area\nFirst Aid: Reception Desk',
    true
),
(
    'NIC Branding',
    'NIC logo and branding information',
    'text',
    'National Incubation Center\nEmpowering Innovation & Entrepreneurship',
    true
);

-- ============================================================================
-- PHASE 6: CREATE UPDATED_AT TRIGGERS
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '⚡ Creating updated_at triggers for new tables...';
END $$;

-- Add updated_at triggers for all new tables
CREATE TRIGGER update_display_content_updated_at
    BEFORE UPDATE ON public.display_content
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_safe();

CREATE TRIGGER update_display_layouts_updated_at
    BEFORE UPDATE ON public.display_layouts
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_safe();

CREATE TRIGGER update_room_displays_updated_at
    BEFORE UPDATE ON public.room_displays
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_safe();

CREATE TRIGGER update_display_content_schedule_updated_at
    BEFORE UPDATE ON public.display_content_schedule
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_safe();

-- ============================================================================
-- PHASE 7: CREATE RLS POLICIES FOR ROOM DISPLAYS
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '🔒 Creating RLS policies for room displays tables...';
END $$;

-- Enable RLS on all new tables
ALTER TABLE public.display_content ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.display_layouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.room_displays ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.display_content_schedule ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.room_display_logs ENABLE ROW LEVEL SECURITY;

-- Display content policies
CREATE POLICY "display_content_select_all" ON public.display_content
    FOR SELECT TO authenticated
    USING (true);

CREATE POLICY "display_content_admin_manage" ON public.display_content
    FOR ALL TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Display layouts policies (read-only for all, admin manage)
CREATE POLICY "display_layouts_select_all" ON public.display_layouts
    FOR SELECT TO authenticated
    USING (true);

CREATE POLICY "display_layouts_admin_manage" ON public.display_layouts
    FOR ALL TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Room displays policies
CREATE POLICY "room_displays_select_all" ON public.room_displays
    FOR SELECT TO authenticated
    USING (true);

CREATE POLICY "room_displays_admin_manage" ON public.room_displays
    FOR ALL TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Display content schedule policies
CREATE POLICY "display_schedule_select_all" ON public.display_content_schedule
    FOR SELECT TO authenticated
    USING (true);

CREATE POLICY "display_schedule_admin_manage" ON public.display_content_schedule
    FOR ALL TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Display logs policies (admin only)
CREATE POLICY "display_logs_admin_only" ON public.room_display_logs
    FOR ALL TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- ============================================================================
-- FINAL SUCCESS MESSAGE
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '🎉 ROOM DISPLAYS DATABASE SCHEMA CREATED SUCCESSFULLY!';
    RAISE NOTICE '✅ All display management tables created';
    RAISE NOTICE '✅ Default layouts and sample content inserted';
    RAISE NOTICE '✅ RLS policies configured for admin access';
    RAISE NOTICE '✅ Room displays created for all existing rooms';
    RAISE NOTICE '📝 Next: Set up Supabase Storage bucket and implement frontend';
END $$;
