# Quick Test: Two Critical Fixes

## 🚀 **Both Critical Issues Fixed - Ready to Test!**

---

## IMPORTANT: Run SQL Script First!

**Before testing, you MUST run the SQL script to fix RLS policies:**

1. Go to **Supabase Dashboard**
2. Click **"SQL Editor"** in left sidebar
3. Click **"New query"**
4. Copy entire contents of `FIX-STARTUPS-RLS-POLICIES.sql`
5. Paste into editor
6. Click **"Run"** (or press Ctrl+Enter)
7. **VERIFY**: Query completes without errors
8. **VERIFY**: Results show two new policies created

**Expected Output:**
```
✅ Helper function created/updated
✅ Policy created: startups_update_admin
✅ Policy created: startups_delete_admin
✅ Test query returns: is_admin = true
```

---

## Test 1: Room Capacities (3 min)

### **Setup**
1. **Hard refresh** application (Ctrl+Shift+R)
2. **Open browser console** (F12)
3. Go to **Room Displays** tab

### **What to Look For**

**Console Output:**
```
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
- [ ] Console shows "Loading room displays from database..."
- [ ] Console shows "Nexus-Session Hall: capacity = 50 (from database)"
- [ ] Console shows "Indus-Board Room: capacity = 25 (from database)"
- [ ] Nexus-Session Hall card shows "50 people"
- [ ] Indus-Board Room card shows "25 people"
- [ ] No errors in console

### **If Still Shows Wrong Capacities**

**Check Console for:**
```
📊 [loadRoomStatusDisplays] Nexus-Session Hall: capacity = 20 (from database)
```

**This means:**
- Database still has old values
- SQL script `UPDATE-ROOM-CAPACITIES.sql` was not run
- Or SQL script failed

**Solution:**
1. Go to Supabase Dashboard → SQL Editor
2. Run this query to check current values:
```sql
SELECT name, capacity FROM public.rooms
WHERE name IN ('Nexus-Session Hall', 'Indus-Board Room')
ORDER BY name;
```
3. If values are wrong (20, 12), run `UPDATE-ROOM-CAPACITIES.sql`
4. Hard refresh application

---

## Test 2: Edit Startup User (5 min)

### **Setup**
1. **Make sure SQL script was run** (RLS policies fixed)
2. **Hard refresh** application (Ctrl+Shift+R)
3. **Open browser console** (F12)
4. Go to **Contact Us** tab
5. Scroll to "Registered Startups" section

### **Test Edit**

**Steps:**
```
1. Find any startup user card
2. Click "Edit" button (yellow)
3. Modal opens
4. Change "Startup Name" to "Test UPDATED"
5. Change "Contact Person" to "Jane Doe UPDATED"
6. Click "Save Changes"
```

### **Expected Console Output (SUCCESS)**
```
🔄 [editStartupUser] Loading startup abc-123...
✅ [editStartupUser] Startup loaded: {...}
🔄 [saveStartupUserChanges] Updating startup abc-123...
📝 [saveStartupUserChanges] Data to update: {
    name: "Test UPDATED",
    contact_person: "Jane Doe UPDATED",
    email: "test@example.com",
    phone: "+92 300 1234567"
}
✅ [saveStartupUserChanges] Database response: [{id: "abc-123", name: "Test UPDATED", ...}]
✅ [saveStartupUserChanges] Startup updated successfully
🔄 [saveStartupUserChanges] Reloading contact data...
```

### **Expected UI (SUCCESS)**
```
✅ Success message: "Startup profile updated successfully"
✅ Modal closes
✅ Card shows: "Test UPDATED"
✅ Card shows: "Contact: Jane Doe UPDATED"
✅ Refresh page → Changes persist
```

### **PASS Criteria**
- [ ] Console shows "Data to update: {...}"
- [ ] Console shows "Database response: [{...}]"
- [ ] Console shows "Startup updated successfully"
- [ ] Success message appears
- [ ] Modal closes
- [ ] Card shows updated name
- [ ] Refresh page → Changes persist
- [ ] No errors in console

### **If Update Fails (RLS ERROR)**

**Console Output:**
```
❌ [saveStartupUserChanges] Database error: {...}
❌ [saveStartupUserChanges] Error details: {
    message: "new row violates row-level security policy",
    details: null,
    hint: null,
    code: "42501"
}
```

**This means:**
- RLS policies were NOT created
- SQL script `FIX-STARTUPS-RLS-POLICIES.sql` was not run
- Or SQL script failed

**Solution:**
1. Go to Supabase Dashboard → SQL Editor
2. Run `FIX-STARTUPS-RLS-POLICIES.sql` again
3. Verify policies were created:
```sql
SELECT policyname FROM pg_policies
WHERE tablename = 'startups'
ORDER BY policyname;
```
4. Should see: `startups_update_admin`, `startups_delete_admin`
5. Hard refresh application
6. Try edit again

---

## Test 3: Delete Startup User (5 min)

### **Setup**
1. **Make sure SQL script was run** (RLS policies fixed)
2. **Create a TEST startup** or use existing one
3. **Open browser console** (F12)
4. Go to **Contact Us** tab

### **Test Delete**

**Steps:**
```
1. Find TEST startup user card
2. Click "Delete" button (red)
3. Confirmation dialog appears
4. Click "OK"
5. Type exact startup name
6. Click "OK"
```

### **Expected Console Output (SUCCESS)**
```
🔄 [deleteStartupUser] Deleting startup abc-123...
🔄 [deleteStartupUser] Startup ID: abc-123
🔄 [deleteStartupUser] Deleting from database...
✅ [deleteStartupUser] Database response: [{id: "abc-123", ...}]
✅ [deleteStartupUser] Startup deleted successfully
🔄 [deleteStartupUser] Reloading contact data...
```

### **Expected UI (SUCCESS)**
```
✅ Success message: "Startup 'Test Startup' deleted successfully"
✅ Card is removed from list
✅ Refresh page → Startup is still deleted
```

### **PASS Criteria**
- [ ] Console shows "Deleting startup abc-123..."
- [ ] Console shows "Startup ID: abc-123"
- [ ] Console shows "Database response: [{...}]"
- [ ] Console shows "Startup deleted successfully"
- [ ] Success message appears
- [ ] Card is removed immediately
- [ ] Refresh page → Startup is still deleted
- [ ] No errors in console

### **If Delete Fails (RLS ERROR)**

**Console Output:**
```
❌ [deleteStartupUser] Database error: {...}
❌ [deleteStartupUser] Error details: {
    message: "new row violates row-level security policy",
    code: "42501"
}
```

**Solution:**
- Same as Edit failure above
- Run `FIX-STARTUPS-RLS-POLICIES.sql`
- Verify policies created
- Hard refresh and try again

---

## Troubleshooting Guide

### **Issue: Room capacities still wrong**

**Symptoms:**
- Console shows: `capacity = 20` or `capacity = 12`
- UI shows old values

**Diagnosis:**
```sql
-- Run in Supabase SQL Editor
SELECT name, capacity FROM public.rooms
WHERE name IN ('Nexus-Session Hall', 'Indus-Board Room');
```

**If shows 20 and 12:**
- Database was NOT updated
- Run `UPDATE-ROOM-CAPACITIES.sql`

**If shows 50 and 25:**
- Database is correct
- Clear browser cache
- Hard refresh (Ctrl+Shift+R)

---

### **Issue: Edit/Delete not working**

**Symptoms:**
- Console shows: `code: "42501"`
- Error message: "row-level security policy"

**Diagnosis:**
```sql
-- Run in Supabase SQL Editor
SELECT policyname FROM pg_policies
WHERE tablename = 'startups'
ORDER BY policyname;
```

**If missing policies:**
- Run `FIX-STARTUPS-RLS-POLICIES.sql`
- Verify policies created
- Hard refresh application

**If policies exist:**
- Check if logged in as admin
- Check `currentUser.role === 'admin'`
- Verify `is_current_user_admin()` function exists

---

### **Issue: No console logs appearing**

**Symptoms:**
- Console is empty
- No logs from functions

**Solution:**
1. Make sure console is open (F12)
2. Make sure "All levels" is selected in console filter
3. Hard refresh (Ctrl+Shift+R)
4. Check if code was deployed to Vercel
5. Clear browser cache

---

## Success Checklist

### **ISSUE 1: Room Capacities**
- [ ] SQL script `UPDATE-ROOM-CAPACITIES.sql` run successfully
- [ ] Console shows "Loading room displays from database..."
- [ ] Console shows "Nexus-Session Hall: capacity = 50 (from database)"
- [ ] Console shows "Indus-Board Room: capacity = 25 (from database)"
- [ ] Nexus-Session Hall card shows "50 people"
- [ ] Indus-Board Room card shows "25 people"
- [ ] No errors in console

### **ISSUE 2: Edit/Delete Startup Users**
- [ ] SQL script `FIX-STARTUPS-RLS-POLICIES.sql` run successfully
- [ ] Policies created: `startups_update_admin`, `startups_delete_admin`
- [ ] Edit button opens modal
- [ ] Edit saves changes to database
- [ ] Console shows "Database response: [{...}]"
- [ ] Edit updates UI immediately
- [ ] Edit changes persist after refresh
- [ ] Delete button shows confirmation
- [ ] Delete removes from database
- [ ] Delete updates UI immediately
- [ ] Delete persists after refresh
- [ ] No RLS errors in console

---

## Quick Summary

**Testing Time:** ~13 minutes total

**What to Test:**
1. ✅ Room capacities (3 min)
2. ✅ Edit startup user (5 min)
3. ✅ Delete startup user (5 min)

**Required SQL Scripts:**
1. `UPDATE-ROOM-CAPACITIES.sql` (if not already run)
2. `FIX-STARTUPS-RLS-POLICIES.sql` (MUST run!)

**Expected Results:**
- ✅ Room Displays shows 50 and 25 people
- ✅ Edit startup saves to database
- ✅ Delete startup removes from database
- ✅ All changes persist after refresh
- ✅ Detailed console logging

---

## 🎯 **Ready to Test!**

1. **Run SQL script** (`FIX-STARTUPS-RLS-POLICIES.sql`)
2. **Deploy code** to Vercel (if not already done)
3. **Hard refresh** application (Ctrl+Shift+R)
4. **Open console** (F12)
5. **Test all three** (~13 minutes)
6. **Check all items** in Success Checklist
7. **Report any issues** with console logs

See **TWO-CRITICAL-FIXES-COMPLETE.md** for complete technical details.

---

**Both critical issues are fixed and ready to test!** 🚀

