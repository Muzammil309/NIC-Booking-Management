# Quick Test: Three Critical Fixes

## 🚀 **All Three Critical Issues Fixed - Ready to Test!**

---

## ⚠️ IMPORTANT: Run SQL Script First!

**Before testing, you MUST run the SQL script:**

1. Go to **Supabase Dashboard**
2. Click **"SQL Editor"** in left sidebar
3. Click **"New query"**
4. Copy entire contents of `FIX-ALL-THREE-ISSUES.sql`
5. Paste into editor
6. Click **"Run"** (or press Ctrl+Enter)
7. **VERIFY**: All queries complete without errors

**Expected Output:**
```
✅ Helper function created: is_current_user_admin()
✅ 4 policies created on users table
✅ Room capacities updated (50 and 25)
✅ All rooms have status
✅ Test queries return expected results
```

---

## Test 1: Admin Account Creation (5 min)

### **Setup**
1. **Hard refresh** application (Ctrl+Shift+R)
2. **Open browser console** (F12)
3. Go to **Contact Us** tab
4. Scroll to **"Admin Contacts"** section

### **Test Create Admin**

**Steps:**
```
1. Click "Add New Admin Contact" button (green)
2. Fill in form:
   - Name: "Test Admin"
   - Email: "testadmin@nic.com" (MUST be NEW email)
   - Phone: "+92 300 1234567"
   - Password: "password123"
3. Click "Create Admin"
```

### **Expected Console Output (SUCCESS)**
```
🔄 [handleCreateAdmin] Creating new admin account...
📝 [handleCreateAdmin] Email: testadmin@nic.com
📝 [handleCreateAdmin] Name: Test Admin
✅ [handleCreateAdmin] Auth user created: abc-123-def-456
✅ [handleCreateAdmin] User profile created: [{id: "abc-123-def-456", ...}]
```

### **Expected UI (SUCCESS)**
```
✅ Success message: "Admin contact created successfully! They will receive a confirmation email."
✅ Form resets
✅ Modal closes after 2 seconds
✅ Contact list reloads
✅ New admin appears in list
```

### **PASS Criteria**
- [ ] Console shows "Creating new admin account..."
- [ ] Console shows "Auth user created: ..."
- [ ] Console shows "User profile created: ..."
- [ ] Success message appears
- [ ] Form resets
- [ ] New admin appears in contact list
- [ ] No errors in console

### **If Creation Fails (RLS ERROR)**

**Console Output:**
```
❌ [handleCreateAdmin] User profile error: {...}
❌ [handleCreateAdmin] Error details: {
    message: "new row violates row-level security policy",
    code: "42501"
}
```

**This means:**
- RLS policies were NOT created
- SQL script `FIX-ALL-THREE-ISSUES.sql` was not run
- Or SQL script failed

**Solution:**
1. Go to Supabase Dashboard → SQL Editor
2. Run `FIX-ALL-THREE-ISSUES.sql` again
3. Verify policies were created:
```sql
SELECT policyname FROM pg_policies
WHERE tablename = 'users'
ORDER BY policyname;
```
4. Should see: `users_insert_admin`, `users_select_all`, `users_update_admin`, `users_delete_admin`
5. Hard refresh application
6. Try create admin again

---

## Test 2: Room Capacities (3 min)

### **Setup**
1. **Hard refresh** application (Ctrl+Shift+R)
2. **Open browser console** (F12)
3. Go to **Room Displays** tab

### **What to Look For**

**Console Output (Database Correct):**
```
🔍 [loadRoomStatusDisplays] Verifying room capacities in database...
📊 [loadRoomStatusDisplays] Database verification:
   Indus-Board Room: capacity = 25, max_duration = 8, status = available
   Nexus-Session Hall: capacity = 50, max_duration = 8, status = available
   Podcast Room: capacity = 4, max_duration = 8, status = available
🔄 [loadRoomStatusDisplays] Loading room displays from database...
✅ [loadRoomStatusDisplays] Fetched room displays: [...]
📊 [loadRoomStatusDisplays] Nexus-Session Hall: capacity = 50 (from database)
📊 [loadRoomStatusDisplays] Indus-Board Room: capacity = 25 (from database)
📊 [createRoomDisplayCard] Nexus-Session Hall: Using capacity 50 from database
📊 [createRoomDisplayCard] Indus-Board Room: Using capacity 25 from database
✅ [loadRoomStatusDisplays] Room display cards rendered
```

**UI Display:**
```
Nexus-Session Hall Card:
┌─────────────────────────────┐
│ Nexus-Session Hall          │
│ [Available]                 │
│ Capacity: 50 people         │ ← Should show 50!
└─────────────────────────────┘

Indus-Board Room Card:
┌─────────────────────────────┐
│ Indus-Board Room            │
│ [Available]                 │
│ Capacity: 25 people         │ ← Should show 25!
└─────────────────────────────┘
```

### **PASS Criteria**
- [ ] Console shows "Verifying room capacities in database..."
- [ ] Console shows "Database verification:"
- [ ] Console shows "Nexus-Session Hall: capacity = 50"
- [ ] Console shows "Indus-Board Room: capacity = 25"
- [ ] Console shows "Using capacity 50 from database"
- [ ] Console shows "Using capacity 25 from database"
- [ ] Nexus-Session Hall card shows "50 people"
- [ ] Indus-Board Room card shows "25 people"
- [ ] No errors in console

### **If Still Shows Wrong Capacities**

**Console Output (Database Wrong):**
```
📊 [loadRoomStatusDisplays] Database verification:
   Indus-Board Room: capacity = 12, max_duration = 8, status = available  ← WRONG!
   Nexus-Session Hall: capacity = 20, max_duration = 8, status = available  ← WRONG!
```

**This means:**
- Database was NOT updated
- SQL script Part 2 failed or was not run

**Solution:**
1. Go to Supabase Dashboard → SQL Editor
2. Run this query to check current values:
```sql
SELECT name, capacity FROM public.rooms
WHERE name IN ('Nexus-Session Hall', 'Indus-Board Room')
ORDER BY name;
```
3. If values are wrong (20, 12), run Part 2 of `FIX-ALL-THREE-ISSUES.sql`:
```sql
UPDATE public.rooms SET capacity = 50, updated_at = NOW()
WHERE name = 'Nexus-Session Hall';

UPDATE public.rooms SET capacity = 25, updated_at = NOW()
WHERE name = 'Indus-Board Room';
```
4. Verify update:
```sql
SELECT name, capacity FROM public.rooms
WHERE name IN ('Nexus-Session Hall', 'Indus-Board Room');
```
5. Hard refresh application (Ctrl+Shift+R)
6. Check console for "Database verification" output

---

## Test 3: Room Status Management (5 min)

### **Setup**
1. **Make sure you're logged in as admin**
2. **Hard refresh** application (Ctrl+Shift+R)
3. **Open browser console** (F12)
4. Go to **Room Displays** tab

### **Test Status Change**

**Steps:**
```
1. Find Nexus-Session Hall card
2. Look for status dropdown (admin only)
3. Current status should be "Available" (green)
4. Click dropdown
5. Select "Maintenance"
6. Wait for success message
```

### **Expected Console Output (SUCCESS)**
```
🔄 [updateRoomStatus] Starting update for room abc-123 to status: maintenance
🔄 [updateRoomStatus] Room ID type: string, value: abc-123
✅ [updateRoomStatus] Database updated successfully: [{...}]
✅ [updateRoomStatus] Updated room: {id: "abc-123", name: "Nexus-Session Hall", status: "maintenance", ...}
🔄 [updateRoomStatus] Reloading room displays...
🔄 [loadRoomStatusDisplays] Loading room displays from database...
✅ [loadRoomStatusDisplays] Room display cards rendered
✅ [updateRoomStatus] Complete!
```

### **Expected UI (SUCCESS)**
```
✅ Success message: "Room status updated to maintenance"
✅ Badge changes from green to yellow
✅ Badge text changes to "Maintenance"
✅ Card reloads with new status
```

### **Test Persistence**

**Steps:**
```
1. After status change, refresh page (F5)
2. Go back to Room Displays tab
3. Check Nexus-Session Hall card
```

**Expected:**
```
✅ Status is still "Maintenance" (yellow)
✅ Changes persisted in database
```

### **PASS Criteria**
- [ ] Console shows "Starting update for room..."
- [ ] Console shows "Database updated successfully"
- [ ] Console shows "Updated room: {...}"
- [ ] Success message appears
- [ ] Badge color changes (yellow for maintenance)
- [ ] Badge text changes to "Maintenance"
- [ ] Refresh → Status persists
- [ ] No RLS errors (code 42501)

### **If Status Update Fails (RLS ERROR)**

**Console Output:**
```
❌ [updateRoomStatus] Database error: {...}
❌ [updateRoomStatus] Error details: {
    message: "new row violates row-level security policy",
    code: "42501"
}
```

**This means:**
- RLS policies on `rooms` table are blocking UPDATE
- Need to add UPDATE policy for admins

**Solution:**
1. Go to Supabase Dashboard → SQL Editor
2. Run this query:
```sql
-- Allow admins to UPDATE rooms
CREATE POLICY rooms_update_admin ON public.rooms
FOR UPDATE
USING (public.is_current_user_admin())
WITH CHECK (public.is_current_user_admin());
```
3. Hard refresh application
4. Try status change again

### **If No Rows Updated**

**Console Output:**
```
⚠️ [updateRoomStatus] No rows updated - room may not exist or RLS policy blocking
```

**This means:**
- Room ID is incorrect
- Or RLS policy is blocking silently

**Solution:**
- Check if room exists in database
- Verify RLS policies allow UPDATE
- Check console for room ID value

---

## Troubleshooting Guide

### **Issue: Admin creation fails with "User not allowed"**

**Symptoms:**
- Error message: "User not allowed"
- Or: "new row violates row-level security policy"

**Diagnosis:**
```sql
-- Check if RLS policies exist
SELECT policyname FROM pg_policies
WHERE tablename = 'users'
ORDER BY policyname;
```

**If missing policies:**
- Run `FIX-ALL-THREE-ISSUES.sql` Part 1
- Verify policies created
- Hard refresh application

---

### **Issue: Room capacities still wrong**

**Symptoms:**
- Console shows: `capacity = 20` or `capacity = 12`
- UI shows old values

**Diagnosis:**
```sql
-- Check database values
SELECT name, capacity FROM public.rooms
WHERE name IN ('Nexus-Session Hall', 'Indus-Board Room');
```

**If shows 20 and 12:**
- Database was NOT updated
- Run `FIX-ALL-THREE-ISSUES.sql` Part 2
- Verify update succeeded
- Hard refresh application

**If shows 50 and 25:**
- Database is correct
- Clear browser cache
- Hard refresh (Ctrl+Shift+R)
- Check if code was deployed

---

### **Issue: Room status not updating**

**Symptoms:**
- Dropdown doesn't change status
- Error: "row-level security policy"

**Diagnosis:**
```sql
-- Check RLS policies on rooms table
SELECT policyname FROM pg_policies
WHERE tablename = 'rooms'
ORDER BY policyname;
```

**If missing UPDATE policy:**
- Add policy for admins to UPDATE rooms
- See solution in Test 3 above

---

## Success Checklist

### **ISSUE 1: Admin Account Creation**
- [ ] SQL script run successfully
- [ ] Policies created on users table
- [ ] Console shows "Auth user created"
- [ ] Console shows "User profile created"
- [ ] Success message appears
- [ ] New admin appears in contact list
- [ ] No RLS errors (code 42501)

### **ISSUE 2: Room Capacities**
- [ ] SQL script run successfully
- [ ] Database has correct values (50 and 25)
- [ ] Console shows "Database verification"
- [ ] Console shows "capacity = 50" for Nexus-Session Hall
- [ ] Console shows "capacity = 25" for Indus-Board Room
- [ ] Console shows "Using capacity 50 from database"
- [ ] Console shows "Using capacity 25 from database"
- [ ] Nexus-Session Hall card shows "50 people"
- [ ] Indus-Board Room card shows "25 people"
- [ ] No errors in console

### **ISSUE 3: Room Status Management**
- [ ] Console shows "Database updated successfully"
- [ ] Console shows "Updated room: {...}"
- [ ] Success message appears
- [ ] Badge color changes correctly
- [ ] Status persists after refresh
- [ ] No RLS errors

---

## Quick Summary

**Testing Time:** ~13 minutes total

**What to Test:**
1. ✅ Admin account creation (5 min)
2. ✅ Room capacities (3 min)
3. ✅ Room status management (5 min)

**Required SQL Script:**
- `FIX-ALL-THREE-ISSUES.sql` (MUST RUN!)

**Expected Results:**
- ✅ Admin users can create new admin accounts
- ✅ Room Displays shows 50 and 25 people
- ✅ Admin can change room status
- ✅ All changes persist after refresh
- ✅ Detailed console logging

---

## 🎯 **Ready to Test!**

1. **Run SQL script** (`FIX-ALL-THREE-ISSUES.sql`) ⚠️ **REQUIRED!**
2. **Deploy code** to Vercel (if not already done)
3. **Hard refresh** application (Ctrl+Shift+R)
4. **Open console** (F12)
5. **Test all three** (~13 minutes)
6. **Check all items** in Success Checklist
7. **Report any issues** with console logs

See **THREE-CRITICAL-FIXES-COMPLETE.md** for complete technical details.

---

**All three critical issues are fixed and ready to test!** 🚀

