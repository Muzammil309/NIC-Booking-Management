# NIC Booking Management - Authentication Guide

## Authentication Behavior Explained

### Current Behavior (Standard Web App)
The application uses **Supabase Authentication** which provides:
- **Session Persistence**: Users stay logged in across browser sessions (like Gmail, Facebook, etc.)
- **Automatic Re-authentication**: Valid sessions are restored when users return
- **Secure Token Management**: JWT tokens are managed automatically by Supabase

This is **NORMAL** and **SECURE** behavior for modern web applications.

### If You Need Force Re-authentication

If your organization requires users to log in every time (high-security environments), uncomment these lines in `index.html`:

#### Option 1: Force logout on every page load
```javascript
// In the DOMContentLoaded event listener (around line 1902)
// SECURITY: Uncomment the next line to force fresh login every time
await supabaseClient.auth.signOut();
```

#### Option 2: Force logout in handleAuthState
```javascript
// In handleAuthState function (around line 1399)
// Check if we should force fresh login (uncomment next line to force re-authentication every time)
await supabaseClient.auth.signOut();
```

#### Option 3: Enable session timeout (30 minutes)
```javascript
// Uncomment the session timeout code (around line 1515-1530)
// This will automatically log out users after 30 minutes of inactivity
```

## Testing Authentication

### Test 1: Normal Login Flow
1. Open the application
2. Enter valid credentials
3. Verify you can access the dashboard
4. Close browser and reopen
5. **Expected**: You should still be logged in (normal behavior)

### Test 2: Invalid Credentials
1. Try logging in with wrong email/password
2. **Expected**: Error message should appear
3. **Expected**: Should NOT be able to access dashboard

### Test 3: Logout Function
1. Log in successfully
2. Click the logout button
3. **Expected**: Should return to login screen
4. **Expected**: Cannot access dashboard without logging in again

### Test 4: Session Validation
1. Log in successfully
2. Go to Supabase Dashboard → Authentication → Users
3. Delete your user account
4. Refresh the application
5. **Expected**: Should be automatically logged out and redirected to login

## Creating Admin Users for Contact Us Page

### Method 1: Via Supabase Dashboard
1. Go to **Supabase Dashboard** → **Authentication** → **Users**
2. Click **"Add User"**
3. Enter:
   - **Email**: admin@nicislamabad.com
   - **Password**: (secure password)
   - **User Metadata**:
     ```json
     {
       "role": "admin",
       "name": "NIC Administrator",
       "phone": "+92-51-XXXXXXX"
     }
     ```
4. Click **"Create User"**

### Method 2: Via SQL (after user signup)
```sql
-- Update existing user to admin
UPDATE auth.users 
SET raw_user_meta_data = raw_user_meta_data || '{"role": "admin", "name": "Admin Name", "phone": "+92-XXX-XXXXXXX"}'::jsonb
WHERE email = 'admin@example.com';

-- Also update the users table if it exists
UPDATE public.users 
SET role = 'admin', name = 'Admin Name', phone = '+92-XXX-XXXXXXX'
WHERE email = 'admin@example.com';
```

## Security Features Implemented

✅ **Session Validation**: Verifies user profile exists before allowing access
✅ **Automatic Logout**: On authentication errors or invalid sessions  
✅ **Error Handling**: Graceful handling of authentication failures
✅ **User Data Cleanup**: Clears currentUser and currentStartup on logout
✅ **Optional Session Timeout**: 30-minute inactivity logout (commented out)
✅ **Force Re-auth Options**: Multiple ways to require fresh login if needed

## Troubleshooting

### Issue: "Users automatically logged in"
- **Cause**: Normal Supabase session persistence
- **Solution**: This is expected behavior. Use force logout options if needed.

### Issue: "Cannot access after login"
- **Cause**: User profile missing or invalid
- **Solution**: Check browser console for errors, verify user exists in database

### Issue: "Contact Us shows no admins"
- **Cause**: No users with role='admin' in database
- **Solution**: Create admin user using methods above

### Issue: "Authentication errors"
- **Cause**: Supabase configuration or network issues
- **Solution**: Check browser console, verify Supabase URL and API key
