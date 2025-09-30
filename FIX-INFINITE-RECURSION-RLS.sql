-- ============================================================================
-- FIX: Infinite Recursion in RLS Policies
-- ============================================================================
-- This script fixes the infinite recursion error in the users and startups
-- RLS policies by removing self-referencing queries.
--
-- PROBLEM:
-- The previous policy had this clause:
--   EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
-- This caused infinite recursion because querying users table triggered
-- the same RLS policy again, creating an infinite loop.
--
-- SOLUTION:
-- Use simpler policies that don't query the same table they're protecting.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- STEP 1: Fix users table RLS policy
-- ----------------------------------------------------------------------------

-- Drop the problematic policy
DROP POLICY IF EXISTS users_select_all ON public.users;

-- Create a new policy without recursion
-- This policy allows:
-- 1. Users to see their own record (id = auth.uid())
-- 2. All users to see all admin users (role = 'admin')
-- 3. We'll handle "admins see all users" in the application layer
CREATE POLICY users_select_all ON public.users
FOR SELECT TO authenticated
USING (
    id = auth.uid()           -- Users can see their own record
    OR role = 'admin'         -- All users can see admin users (for Contact Us)
);

-- ----------------------------------------------------------------------------
-- STEP 2: Create a helper function to check if user is admin
-- ----------------------------------------------------------------------------

-- This function uses SECURITY DEFINER to bypass RLS when checking admin status
-- This prevents infinite recursion when other policies need to check if user is admin
CREATE OR REPLACE FUNCTION public.is_current_user_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.users
        WHERE id = auth.uid() AND role = 'admin'
    );
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.is_current_user_admin() TO authenticated;

-- ----------------------------------------------------------------------------
-- STEP 3: Fix startups table RLS policy using the helper function
-- ----------------------------------------------------------------------------

-- Drop the old policy
DROP POLICY IF EXISTS startups_select_all ON public.startups;

-- Create a new policy using the helper function
-- This policy allows:
-- 1. Users to see their own startup (user_id = auth.uid())
-- 2. Admin users to see all startups (using helper function)
CREATE POLICY startups_select_all ON public.startups
FOR SELECT TO authenticated
USING (
    user_id = auth.uid()                    -- Users can see their own startup
    OR public.is_current_user_admin()       -- Admins can see all startups
);

-- ----------------------------------------------------------------------------
-- STEP 4: Add a policy to allow admins to see all users
-- ----------------------------------------------------------------------------

-- Add an additional policy specifically for admin users to see all users
-- This uses the helper function to avoid recursion
CREATE POLICY users_select_all_for_admins ON public.users
FOR SELECT TO authenticated
USING (
    public.is_current_user_admin()    -- If user is admin, they can see all users
);

-- ----------------------------------------------------------------------------
-- VERIFICATION QUERIES
-- ----------------------------------------------------------------------------

-- Run these queries to verify the policies work correctly:

-- 1. Check all policies on users table
-- SELECT tablename, policyname, cmd, qual 
-- FROM pg_policies 
-- WHERE tablename = 'users' AND cmd = 'SELECT';

-- 2. Check all policies on startups table
-- SELECT tablename, policyname, cmd, qual 
-- FROM pg_policies 
-- WHERE tablename = 'startups' AND cmd = 'SELECT';

-- 3. Test querying admin users (should return 5 rows)
-- SELECT id, name, email, role FROM public.users WHERE role = 'admin' ORDER BY name;

-- 4. Test querying all users (should return 8 rows for admin users)
-- SELECT id, name, email, role FROM public.users ORDER BY created_at DESC;

-- 5. Test the helper function
-- SELECT public.is_current_user_admin();

-- ============================================================================
-- EXPECTED RESULTS
-- ============================================================================
--
-- After running this script:
-- ✅ No infinite recursion errors
-- ✅ Contact Us tab shows all 5 admin profiles
-- ✅ Schedule tab loads without errors
-- ✅ Room Displays tab loads without errors
-- ✅ Startups tab shows all 8 users (for admin users)
-- ✅ Registered Startups shows all startups (for admin users)
--
-- Access Control Rules:
-- ✅ All users can see their own record
-- ✅ All users can see all admin users (for Contact Us)
-- ✅ Admin users can see all users (for Startups management)
-- ✅ Users can see their own startup
-- ✅ Admin users can see all startups
-- ============================================================================

