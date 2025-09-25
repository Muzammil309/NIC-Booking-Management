# Database Script Execution Guide - RLS Policy Fix

## ✅ **FIXED DATABASE SCRIPT READY FOR EXECUTION!**

### **🔧 Issues Resolved in Updated Script**

**Problem**: Duplicate policy errors when running database script
- `ERROR: 42710: policy "Users can create their own profile" for table "users" already exists`
- `ERROR: 42710: policy "Users can create their own startup" for table "startups" already exists`

**Solution**: Enhanced policy cleanup with proper error handling and verification

## **🚀 Step-by-Step Execution Instructions**

### **Step 1: Prepare for Script Execution**
1. **Open Supabase Dashboard** → Go to your project
2. **Navigate to SQL Editor** → Click "SQL Editor" in the left sidebar
3. **Clear any existing queries** in the editor
4. **Copy the entire `database-setup-corrected.sql` content** and paste it into the SQL Editor

### **Step 2: Execute the Database Script**
1. **Click "Run" button** in the SQL Editor
2. **Monitor the output** for success messages and any errors
3. **Look for these key success indicators**:
   ```
   🔍 Verifying RLS policies...
   Table users: X RLS policies created
   Table startups: X RLS policies created
   ✅ CRITICAL: Users table INSERT policy created successfully
   ✅ CRITICAL: Startups table INSERT policy created successfully
   🎉 Database setup completed successfully!
   🚀 Database is ready for the NIC Booking Management System!
   ```

### **Step 3: Verify Script Execution Success**
**Expected Output Messages:**
- ✅ `Policy cleanup completed successfully`
- ✅ `Successfully inserted 9 sample rooms`
- ✅ `CRITICAL: Users table INSERT policy created successfully`
- ✅ `CRITICAL: Startups table INSERT policy created successfully`
- ✅ `Database setup completed successfully!`

**If you see any errors:**
- Check the error message details
- Ensure you have proper permissions in Supabase
- Try running the script again (it's designed to be idempotent)

## **🔧 Enhanced Policy Cleanup Features**

### **Robust Policy Removal**
The updated script includes enhanced policy cleanup:

```sql
-- Enhanced policy cleanup with proper error handling
DO $$
DECLARE
    policy_name text;
    policy_names text[] := ARRAY[
        'Users can view their own profile',
        'Users can update their own profile', 
        'Users can create their own profile',
        'Admins can view all users',
        'Admins can manage all users'
    ];
BEGIN
    FOREACH policy_name IN ARRAY policy_names
    LOOP
        BEGIN
            EXECUTE format('DROP POLICY IF EXISTS %I ON public.users', policy_name);
            RAISE NOTICE 'Dropped policy: % on users table', policy_name;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Policy % may not exist on users table: %', policy_name, SQLERRM;
        END;
    END LOOP;
    -- ... similar for other tables
END $$ LANGUAGE plpgsql;
```

### **Policy Verification System**
The script now verifies that critical policies were created:

```sql
-- Verify critical policies exist
IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'users' 
    AND policyname = 'Users can create their own profile'
    AND schemaname = 'public'
) THEN
    RAISE NOTICE '✅ CRITICAL: Users table INSERT policy created successfully';
ELSE
    RAISE NOTICE '❌ ERROR: Users table INSERT policy NOT found';
END IF;
```

## **🎯 After Script Execution - Test Profile Creation**

### **Step 4: Test Manual Startup Profile Creation**
1. **Go back to your NIC Booking Management application**
2. **Navigate to Settings tab**
3. **Click "Create Missing Startup Profile"** button
4. **Enter your startup name** when prompted
5. **Check for success message** (should work without RLS errors now)

### **Step 5: Verify Profile Creation Success**
**In Settings Tab Debug Information:**
- ✅ **User Profile**: Should show your existing user data
- ✅ **Startup Profile**: Should now show the newly created startup data
- ✅ **"Create Missing Startup Profile" button**: Should be hidden (no longer needed)

### **Step 6: Test Booking Functionality**
1. **Navigate to "Book a Room" tab**
2. **Try to book any available room**
3. **Verify booking works** without "No startup profile found" error
4. **Check "My Bookings" tab** to see your booking

## **🔍 Troubleshooting Guide**

### **If Script Execution Fails:**

**Error: Permission Denied**
- Ensure you're using the correct Supabase project
- Check that you have admin/owner permissions
- Try refreshing the Supabase dashboard and try again

**Error: Still Getting Duplicate Policy Errors**
- The enhanced cleanup should handle this, but if it persists:
- Manually drop policies in Supabase Dashboard → Authentication → Policies
- Then run the script again

**Error: Syntax Errors**
- Ensure you copied the entire script content
- Check that no characters were corrupted during copy/paste
- Try copying the script again from the file

### **If Manual Profile Creation Still Fails:**

**Check Console Logs:**
- Open browser developer tools (F12)
- Look for detailed error messages
- Check if the error mentions RLS policies

**Verify Policy Updates:**
- Go to Supabase Dashboard → Authentication → Policies
- Check that "Users can create their own profile" policy exists for users table
- Check that "Users can create their own startup" policy exists for startups table

**Check User Authentication:**
- Ensure you're logged in to the application
- Try logging out and logging back in
- Check that currentUser exists in Settings tab debug info

## **🚀 Expected Final State**

### **Database:**
- ✅ All tables created with proper schema
- ✅ Updated RLS policies with permissive signup logic
- ✅ Sample room data loaded
- ✅ Triggers and functions working

### **Application:**
- ✅ User profile exists and visible in Settings
- ✅ Startup profile created and visible in Settings
- ✅ Room booking functionality works without errors
- ✅ Complete end-to-end user flow functional

### **User Experience:**
- ✅ Can register new accounts without RLS errors
- ✅ Can create missing startup profiles manually
- ✅ Can book rooms immediately after profile creation
- ✅ Can view and edit profile information in Settings

## **🎉 Success Indicators**

**You'll know everything is working when:**
1. **Database script runs** without any duplicate policy errors
2. **Settings tab shows** both user and startup profiles
3. **"Create Missing Startup Profile" button** is hidden (not needed)
4. **Room booking works** without "No startup profile found" error
5. **Console logs show** successful profile operations

The enhanced database script with robust policy cleanup and verification will resolve the duplicate policy errors and enable proper startup profile creation! 🚀
