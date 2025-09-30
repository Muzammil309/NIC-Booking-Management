# Step-by-Step Guide: Fix jawad@nic.com Account

## 🎯 Goal
Fix the broken `jawad@nic.com` admin account so that:
- ✅ You can login with the credentials
- ✅ The account appears in the Contact Us tab
- ✅ The account has full admin privileges

---

## 📋 Choose Your Method

I recommend **Method 1** (SQL Insert) as it's the fastest and preserves the existing auth user.

---

# Method 1: SQL Insert (RECOMMENDED) ⭐

**Time Required**: 3-5 minutes
**Difficulty**: Easy (just copy-paste)
**Preserves**: Existing auth user and password

## Step 1: Get the Auth User UUID

1. **Open Supabase Dashboard**
   - Go to: https://supabase.com/dashboard
   - Login if needed

2. **Select Your Project**
   - Click on: **nic-booking-management**

3. **Navigate to Authentication**
   - In the left sidebar, click: **Authentication**
   - Click: **Users**

4. **Find the User**
   - Look for the user with email: `jawad@nic.com`
   - You should see it in the list

5. **Copy the User UID**
   - Click on the `jawad@nic.com` user row to view details
   - Find the field labeled: **User UID** or **ID**
   - It looks like: `a1b2c3d4-e5f6-7890-abcd-ef1234567890`
   - **Copy this entire UUID** (you'll need it in Step 2)

   **Example of what you'll see:**
   ```
   User UID: a1b2c3d4-e5f6-7890-abcd-ef1234567890
   Email: jawad@nic.com
   Created: 2025-09-30
   ```

---

## Step 2: Run the SQL Query

1. **Open SQL Editor**
   - In Supabase Dashboard, click: **SQL Editor** (in left sidebar)
   - Click: **New query**

2. **Paste This SQL**
   - Copy the SQL below
   - **IMPORTANT**: Replace `YOUR_AUTH_USER_ID_HERE` with the UUID you copied in Step 1

```sql
-- Insert the missing user record for jawad@nic.com
INSERT INTO public.users (id, email, name, role, phone, created_at)
VALUES (
    'YOUR_AUTH_USER_ID_HERE',  -- ⚠️ REPLACE with UUID from Step 1
    'jawad@nic.com',
    'Jawad Ahmad',
    'admin',
    NULL,
    NOW()
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    name = EXCLUDED.name,
    role = EXCLUDED.role;
```

3. **Example with Real UUID**
   ```sql
   -- Example (your UUID will be different)
   INSERT INTO public.users (id, email, name, role, phone, created_at)
   VALUES (
       'a1b2c3d4-e5f6-7890-abcd-ef1234567890',  -- Your actual UUID
       'jawad@nic.com',
       'Jawad Ahmad',
       'admin',
       NULL,
       NOW()
   );
   ```

4. **Run the Query**
   - Click: **Run** button (or press Ctrl+Enter)
   - You should see: `Success. No rows returned` or `Success. 1 row affected`

---

## Step 3: Verify the Fix

1. **Check the Users Table**
   - In Supabase Dashboard, click: **Table Editor**
   - Select table: **users**
   - Look for the row with email: `jawad@nic.com`
   - You should see:
     ```
     id: a1b2c3d4-... (the UUID you used)
     email: jawad@nic.com
     name: Jawad Ahmad
     role: admin
     phone: NULL
     created_at: 2025-09-30...
     ```

2. **Run Verification SQL** (Optional)
   - Go back to SQL Editor
   - Run this query:
   ```sql
   SELECT id, email, name, role, phone
   FROM public.users
   WHERE email = 'jawad@nic.com';
   ```
   - Should return 1 row with the user details

---

## Step 4: Test in the Application

1. **Check Contact Us Tab**
   - Go to your NIC Booking app
   - Navigate to: **Contact Us** tab
   - You should now see:
     ```
     NIC Admin Contacts
     
     admin
     admin@nic.com
     
     Jawad Ahmad
     jawad@nic.com
     ```

2. **Test Login**
   - Logout from current session
   - Click: **Login**
   - Enter:
     - Email: `jawad@nic.com`
     - Password: (the password you set when creating the account)
   - Click: **Login**
   - **Expected**: Login successful, admin dashboard loads

3. **Verify Admin Access**
   - After logging in as jawad@nic.com
   - Check that you can access:
     - ✅ Dashboard
     - ✅ Startups tab
     - ✅ Book a Room
     - ✅ My Bookings
     - ✅ Schedule
     - ✅ Room Displays
     - ✅ Reports
     - ✅ Policies
     - ✅ Contact Us
     - ✅ Settings

---

## ✅ Success Indicators

If everything worked correctly:
- ✅ SQL query ran without errors
- ✅ User record exists in `public.users` table
- ✅ Jawad Ahmad appears in Contact Us tab
- ✅ Can login with jawad@nic.com
- ✅ Has admin privileges and can access all tabs

---

# Method 2: Table Editor (GUI Method)

**Time Required**: 5 minutes
**Difficulty**: Easy (no SQL needed)
**Preserves**: Existing auth user and password

## Step 1: Get the Auth User UUID
(Same as Method 1, Step 1)

## Step 2: Insert via Table Editor

1. **Open Table Editor**
   - In Supabase Dashboard, click: **Table Editor**
   - Select table: **users**

2. **Insert New Row**
   - Click: **Insert** button (top right)
   - Select: **Insert row**

3. **Fill in the Fields**
   - **id**: Paste the UUID you copied (e.g., `a1b2c3d4-e5f6-7890-abcd-ef1234567890`)
   - **email**: `jawad@nic.com`
   - **name**: `Jawad Ahmad`
   - **role**: `admin`
   - **phone**: Leave empty (or add phone number if you want)
   - **created_at**: Leave as default (will auto-fill with current timestamp)

4. **Save**
   - Click: **Save** button
   - You should see the new row appear in the table

## Step 3: Verify
(Same as Method 1, Steps 3 and 4)

---

# Method 3: Delete and Recreate (EASIEST)

**Time Required**: 2 minutes
**Difficulty**: Very Easy
**Note**: You'll need to set a new password

## Step 1: Delete the Auth User

1. **Open Supabase Dashboard**
   - Go to: https://supabase.com/dashboard
   - Select project: **nic-booking-management**

2. **Navigate to Authentication**
   - Click: **Authentication** → **Users**

3. **Find and Delete**
   - Find the user: `jawad@nic.com`
   - Click the **three dots (...)** on the right
   - Click: **Delete user**
   - Confirm: **Delete**

## Step 2: Recreate Using Fixed Code

1. **Open NIC Booking App**
   - Login as admin (admin@nic.com)

2. **Go to Startups Tab**
   - Click: **Startups** in the sidebar

3. **Create Admin Account**
   - Click: **Create Admin Account** button (green button, top right)
   - You'll see an information dialog - click OK

4. **Enter Details**
   - **Email**: `jawad@nic.com`
   - **Password**: Choose a new password (min 6 characters)
   - **Name**: `Jawad Ahmad`
   - **Phone**: `+92-XXX-XXXXXXX` (optional, can skip)

5. **Success!**
   - You should see: "Admin account created successfully!"
   - The account will appear in Contact Us tab immediately

## Step 3: Verify
- Check Contact Us tab → Should see Jawad Ahmad
- Logout and login as jawad@nic.com → Should work!

---

# Troubleshooting

## Error: "duplicate key value violates unique constraint"

**Cause**: A user record already exists with that email or ID

**Solution**:
1. Check if the user already exists:
   ```sql
   SELECT * FROM public.users WHERE email = 'jawad@nic.com';
   ```
2. If it exists, the account is already fixed! Try logging in.
3. If you see a duplicate, delete it first:
   ```sql
   DELETE FROM public.users WHERE email = 'jawad@nic.com';
   ```
4. Then run the INSERT query again

---

## Error: "foreign key violation"

**Cause**: The UUID you're using doesn't exist in auth.users

**Solution**:
1. Double-check you copied the correct UUID from Supabase Dashboard
2. Make sure you're looking at the jawad@nic.com user
3. The UUID should be exactly 36 characters (including dashes)
4. If still failing, use Method 3 (Delete and Recreate)

---

## Can't Find User in Authentication

**Cause**: The auth user might have been deleted

**Solution**:
- Use Method 3 (Delete and Recreate)
- The "Create Admin Account" button will create a fresh, working account

---

## Login Still Fails After Fix

**Possible causes**:
1. Wrong password
2. Email not confirmed
3. Browser cache

**Solutions**:
1. Try password reset (if available)
2. Check Supabase Dashboard → Authentication → Users → jawad@nic.com → Confirm email
3. Clear browser cache and cookies
4. Try in incognito/private window
5. Check browser console (F12) for errors

---

## User Not Appearing in Contact Us

**Possible causes**:
1. User record not created
2. Role is not 'admin'
3. Page not refreshed

**Solutions**:
1. Verify user exists in database:
   ```sql
   SELECT * FROM public.users WHERE email = 'jawad@nic.com';
   ```
2. Check role is 'admin':
   ```sql
   UPDATE public.users SET role = 'admin' WHERE email = 'jawad@nic.com';
   ```
3. Hard refresh the page (Ctrl+Shift+R)
4. Logout and login again

---

# Quick Reference

## SQL to Check if User Exists
```sql
SELECT id, email, name, role FROM public.users WHERE email = 'jawad@nic.com';
```

## SQL to Check All Admins
```sql
SELECT id, email, name, role FROM public.users WHERE role = 'admin' ORDER BY name;
```

## SQL to Update Role to Admin
```sql
UPDATE public.users SET role = 'admin' WHERE email = 'jawad@nic.com';
```

## SQL to Add Phone Number Later
```sql
UPDATE public.users SET phone = '+92-300-1234567' WHERE email = 'jawad@nic.com';
```

## SQL to Delete User (if needed)
```sql
DELETE FROM public.users WHERE email = 'jawad@nic.com';
```

---

# Recommended Approach

**I recommend Method 1 (SQL Insert)** because:
- ✅ Fastest (3-5 minutes)
- ✅ Preserves existing auth user
- ✅ Preserves existing password
- ✅ Just copy-paste SQL
- ✅ Easy to verify

**Use Method 3 (Delete and Recreate)** if:
- ❌ You can't find the UUID
- ❌ You don't mind setting a new password
- ❌ You want the absolute simplest solution

---

# After Fixing

Once the account is fixed, you should be able to:

1. **Login as jawad@nic.com**
   - Use the email and password
   - Access full admin dashboard

2. **See in Contact Us**
   - All users can see Jawad Ahmad in admin contacts
   - Email and phone (if added) are displayed

3. **Manage the Account**
   - Edit name/phone via Startups tab → Edit button
   - Change password via Settings (if implemented)
   - Toggle role if needed (though you want to keep it as admin)

---

# Need More Help?

If you encounter any issues not covered here:
1. Check the browser console (F12) for error messages
2. Check Supabase Dashboard → Logs for database errors
3. Verify the UUID matches between auth.users and public.users
4. Try Method 3 (Delete and Recreate) as a last resort

**The fix should work immediately - no app restart or deployment needed!**

