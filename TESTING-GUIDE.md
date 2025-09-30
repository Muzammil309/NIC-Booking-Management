# NIC Booking Management System - Testing Guide

## Quick Testing Instructions

### 1. Testing Admin Account Creation

#### Test Case 1: Create New Admin (Success)
1. Login as admin user
2. Go to **Startups** tab
3. Click **"Create Admin Account"** button
4. Enter a NEW email (e.g., `newadmin@nic.com`)
5. Enter password (min 6 characters)
6. Enter admin name
7. **Expected**: Success message, new admin appears in users table

#### Test Case 2: Duplicate Admin Email (Error)
1. Click **"Create Admin Account"** button
2. Enter an EXISTING admin email (e.g., `admin@nic.com`)
3. **Expected**: Error message showing "An admin account with email already exists"

#### Test Case 3: Convert Startup to Admin (Conversion)
1. First, note an existing startup user's email
2. Click **"Create Admin Account"** button
3. Enter the startup user's email
4. **Expected**: Confirmation dialog asking if you want to convert the user to admin
5. Click **OK** to confirm
6. **Expected**: Success message, user's role changes to "admin" in the table

#### Test Case 4: Cancel Conversion
1. Click **"Create Admin Account"** button
2. Enter an existing startup user's email
3. **Expected**: Confirmation dialog
4. Click **Cancel**
5. **Expected**: Info message "Admin account creation cancelled"

---

### 2. Testing Startups Tab Display

#### Test Case 1: Verify All Users Displayed
1. Login as admin user
2. Go to **Startups** tab
3. **Expected**: See ALL users in the table (both admin and startup users)
4. **Verify**: Each row shows:
   - User name and email
   - Associated startup (if any)
   - Role badge (admin or startup)
   - Status (Active)
   - Edit and Toggle Role buttons

#### Test Case 2: Edit User Profile
1. Click **"Edit"** button on any user row
2. **Expected**: Edit modal opens with user data
3. Modify name, email, or phone
4. Click **"Save Changes"**
5. **Expected**: Success message, table refreshes with updated data

#### Test Case 3: Toggle User Role
1. Find a startup user in the table
2. Click **"Make Admin"** button
3. **Expected**: User's role changes to "admin", button changes to "Make Startup"
4. Click **"Make Startup"** button
5. **Expected**: User's role changes back to "startup"

---

### 3. Testing Contact Us Tab

#### Test Case 1: Startup User View
1. **Logout** and login as a **startup user**
2. Go to **Contact Us** tab
3. **Expected to see**:
   - ✅ NIC official contact information
   - ✅ List of ALL admin profiles with names, emails, phones
   - ✅ Email and Call buttons for each admin
4. **Expected NOT to see**:
   - ❌ Registered startups list (this is admin-only)

#### Test Case 2: Admin User View
1. **Logout** and login as an **admin user**
2. Go to **Contact Us** tab
3. **Expected to see**:
   - ✅ NIC official contact information
   - ✅ List of ALL admin profiles
   - ✅ List of ALL registered startups (purple section)
   - ✅ Email and Call buttons for both admins and startups

---

### 4. Testing Room Display Fullscreen Lock (CRITICAL)

#### Test Case 1: Admin User Fullscreen
1. Login as **admin user**
2. Go to **Room Displays** tab
3. Click on any room card (e.g., "Hingol")
4. **Expected**: Room preview modal opens
5. Click **"Fullscreen"** button
6. **Expected**: Display enters fullscreen mode, info message appears
7. Press **ESC** key
8. **Expected**: Simple confirmation dialog "You are about to exit fullscreen display mode. Continue?"
9. Click **OK**
10. **Expected**: Exits fullscreen successfully

#### Test Case 2: Non-Admin User Fullscreen Lock
1. **Logout** (or open in incognito/private window)
2. Navigate to the room display preview (you may need to access it directly)
3. Click **"Fullscreen"** button
4. **Expected**: Display enters fullscreen mode
5. Press **ESC** key
6. **Expected**: Password prompt appears: "🔒 DISPLAY LOCKED - Enter the admin password to exit fullscreen mode"
7. Enter **WRONG** password
8. **Expected**: Error message "Incorrect password. Access denied.", stays in fullscreen
9. Press **ESC** key again
10. Enter **CORRECT** admin password (e.g., password for admin@nic.com)
11. **Expected**: Success message, exits fullscreen

#### Test Case 3: Fullscreen Auto Re-lock
1. As non-admin user, enter fullscreen mode
2. Try to exit fullscreen using **browser controls** (F11, or browser menu)
3. **Expected**: Password prompt appears
4. Click **Cancel** or enter wrong password
5. **Expected**: Display automatically re-enters fullscreen mode
6. **Verify**: User cannot escape fullscreen without correct password

#### Test Case 4: Close Modal While in Fullscreen
1. As non-admin user, enter fullscreen mode
2. Click the **X (close)** button on the modal
3. **Expected**: Password prompt appears
4. Enter wrong password
5. **Expected**: Modal stays open, remains in fullscreen
6. Click **X** button again
7. Enter correct admin password
8. **Expected**: Exits fullscreen, closes modal

#### Test Case 5: Click Outside Modal While in Fullscreen
1. As non-admin user, enter fullscreen mode
2. Click **outside the modal** (on the dark overlay)
3. **Expected**: Password prompt appears
4. Enter correct password
5. **Expected**: Exits fullscreen, closes modal

---

## Browser Compatibility Testing

Test the fullscreen lock feature on multiple browsers:

### Chrome/Edge (Chromium)
- ✅ Fullscreen API: `requestFullscreen()`
- ✅ ESC key interception
- ✅ Auto re-lock

### Firefox
- ✅ Fullscreen API: `mozRequestFullScreen()`
- ✅ ESC key interception
- ✅ Auto re-lock

### Safari
- ✅ Fullscreen API: `webkitRequestFullscreen()`
- ✅ ESC key interception
- ✅ Auto re-lock

### Testing on Physical Display Screens
1. Connect a tablet or display screen to show the room display
2. Open the room preview in fullscreen mode
3. Leave the display unattended
4. Have someone try to exit fullscreen or navigate away
5. **Verify**: Password prompt appears and prevents unauthorized exit

---

## Common Issues and Solutions

### Issue: "User already registered" error
**Solution**: The new code now checks for existing users and offers to convert them to admin if they're startup users.

### Issue: Can't see admin contacts as startup user
**Solution**: This should already work. Verify you're on the Contact Us tab and logged in as a startup user.

### Issue: Fullscreen lock not working
**Possible causes**:
1. Browser doesn't support Fullscreen API (very rare)
2. User is logged in as admin (admins get simple confirmation, not password lock)
3. JavaScript error - check browser console

**Solution**: 
- Test in different browser
- Verify user is NOT logged in as admin
- Check browser console for errors

### Issue: Can't exit fullscreen even with correct password
**Solution**: 
- Make sure you're entering the password for the admin@nic.com account
- Check that the admin account exists and password is correct
- Try refreshing the page and re-entering fullscreen

---

## Security Notes

### Admin Password
- The fullscreen lock uses the password for `admin@nic.com` by default
- Make sure this account exists and the password is known to authorized personnel
- Document the password securely for staff who need to manage displays

### Customizing Admin Email
If you want to use a different admin email for password verification, update this line in the code:

```javascript
// In verifyAdminPasswordForExit() function
const { error } = await supabaseClient.auth.signInWithPassword({
    email: 'admin@nic.com', // Change this to your preferred admin email
    password: password
});
```

---

## Success Criteria

All tests should pass with these results:

✅ **Admin Account Creation**
- New admins can be created successfully
- Duplicate emails are detected and handled appropriately
- Startup users can be converted to admin with confirmation

✅ **Startups Tab**
- All users (admin and startup) are displayed
- Edit and Toggle Role functions work correctly

✅ **Contact Us Tab**
- Startup users see all admin contacts
- Startup users do NOT see registered startups list
- Admin users see both admin contacts AND registered startups

✅ **Room Display Fullscreen Lock**
- Admin users can exit fullscreen with simple confirmation
- Non-admin users MUST enter correct password to exit
- ESC key is intercepted and requires password
- Auto re-lock works if user tries to exit without password
- Modal close requires password when in fullscreen

---

## Reporting Issues

If you encounter any issues during testing:

1. **Note the exact steps** that led to the issue
2. **Check browser console** for error messages (F12 → Console tab)
3. **Note your user role** (admin or startup)
4. **Note the browser** and version you're using
5. **Take screenshots** if applicable

Provide this information for faster troubleshooting and fixes.

