-- FIX ISSUE 2: Enable Admin Users to UPDATE and DELETE Startups
-- This script adds RLS policies to allow admin users to manage startup users

-- First, check if the helper function exists (created in previous fix)
-- If not, create it
CREATE OR REPLACE FUNCTION public.is_current_user_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid() AND role = 'admin'
    );
$$;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS startups_update_admin ON public.startups;
DROP POLICY IF EXISTS startups_delete_admin ON public.startups;

-- Create policy to allow admins to UPDATE any startup
CREATE POLICY startups_update_admin ON public.startups
FOR UPDATE
USING (
    -- Allow if user is admin
    public.is_current_user_admin()
    OR
    -- Allow if user owns the startup
    user_id = auth.uid()
)
WITH CHECK (
    -- Allow if user is admin
    public.is_current_user_admin()
    OR
    -- Allow if user owns the startup
    user_id = auth.uid()
);

-- Create policy to allow admins to DELETE any startup
CREATE POLICY startups_delete_admin ON public.startups
FOR DELETE
USING (
    -- Allow if user is admin
    public.is_current_user_admin()
    OR
    -- Allow if user owns the startup
    user_id = auth.uid()
);

-- Verify the policies were created
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
WHERE tablename = 'startups'
ORDER BY policyname;

-- Test the helper function
SELECT public.is_current_user_admin() AS is_admin;

-- Expected results:
-- 1. Helper function created/updated
-- 2. Two new policies created: startups_update_admin, startups_delete_admin
-- 3. Test query should return true if logged in as admin

