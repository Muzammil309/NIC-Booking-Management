# Quick Test: Three Fixes

## 🚀 **All Three Fixes Ready to Test!**

---

## Test 1: Room Duration Display (2 min)

### **What to Test**
Verify that Indus-Board Room, Nexus-Session Hall, and Podcast Room show "8 hours max"

### **Steps**

1. **Reload page** (F5 or Ctrl+Shift+R)
2. Go to **Book a Room** tab
3. Click on **Room** dropdown

### **Test Each Room**

**Indus-Board Room:**
```
1. Select "Indus-Board Room" from dropdown
2. Look at room preview section on the right
3. Find "Max Duration:" field
4. VERIFY: Shows "8 hours max" ✅
```

**Nexus-Session Hall:**
```
1. Select "Nexus-Session Hall" from dropdown
2. Look at room preview section
3. Find "Max Duration:" field
4. VERIFY: Shows "8 hours max" ✅
```

**Podcast Room:**
```
1. Select "Podcast Room" from dropdown
2. Look at room preview section
3. Find "Max Duration:" field
4. VERIFY: Shows "8 hours max" ✅
```

**Other Rooms (Should Still Show 2 Hours):**
```
1. Select "HUB (Focus Room)" from dropdown
2. VERIFY: Shows "2 hours max" ✅
3. Select "Hingol (Focus Room)" from dropdown
4. VERIFY: Shows "2 hours max" ✅
```

### **Expected Result**

```
Room Preview Section:
┌─────────────────────────────┐
│ Indus-Board Room            │
│ Capacity: 25 people         │
│ Type: Special Room          │
│ Max Duration: 8 hours max   │ ← Should show 8 hours!
│ Equipment: ...              │
└─────────────────────────────┘
```

**PASS Criteria:**
- [ ] Indus-Board Room shows "8 hours max"
- [ ] Nexus-Session Hall shows "8 hours max"
- [ ] Podcast Room shows "8 hours max"
- [ ] HUB (Focus Room) shows "2 hours max"
- [ ] Other focus rooms show "2 hours max"

---

## Test 2: Room Capacity Display (3 min)

### **Step 1: Update Database**

**Go to Supabase:**
1. Open Supabase Dashboard
2. Click **"SQL Editor"** in left sidebar
3. Click **"New query"**
4. Copy this SQL:

```sql
-- Update Nexus-Session Hall capacity
UPDATE public.rooms
SET capacity = 50, updated_at = NOW()
WHERE name = 'Nexus-Session Hall';

-- Update Indus-Board Room capacity
UPDATE public.rooms
SET capacity = 25, updated_at = NOW()
WHERE name = 'Indus-Board Room';

-- Verify
SELECT name, capacity FROM public.rooms
WHERE name IN ('Nexus-Session Hall', 'Indus-Board Room')
ORDER BY name;
```

5. Click **"Run"** (or press Ctrl+Enter)
6. **VERIFY**: Results show:
   - Indus-Board Room: capacity = 25
   - Nexus-Session Hall: capacity = 50

### **Step 2: Test in Application**

**Book a Room Tab:**
```
1. Reload application (F5)
2. Go to "Book a Room" tab
3. Select "Nexus-Session Hall"
4. VERIFY: Shows "Capacity: 50 people" ✅
5. Select "Indus-Board Room"
6. VERIFY: Shows "Capacity: 25 people" ✅
```

**Room Displays Tab:**
```
1. Go to "Room Displays" tab
2. Find "Nexus-Session Hall" card
3. VERIFY: Shows "Capacity: 50 people" ✅
4. Find "Indus-Board Room" card
5. VERIFY: Shows "Capacity: 25 people" ✅
```

**Fullscreen Preview:**
```
1. Click on "Nexus-Session Hall" card
2. Preview modal opens
3. VERIFY: Shows "Capacity: 50 people" ✅
4. Close modal
5. Click on "Indus-Board Room" card
6. VERIFY: Shows "Capacity: 25 people" ✅
```

### **Expected Result**

```
Nexus-Session Hall Card:
┌─────────────────────────────┐
│ Nexus-Session Hall          │
│ [Available]                 │
│                             │
│ Capacity: 50 people         │ ← Should show 50!
│ Type: Special Room          │
└─────────────────────────────┘

Indus-Board Room Card:
┌─────────────────────────────┐
│ Indus-Board Room            │
│ [Available]                 │
│                             │
│ Capacity: 25 people         │ ← Should show 25!
│ Type: Special Room          │
└─────────────────────────────┘
```

**PASS Criteria:**
- [ ] SQL query runs successfully
- [ ] Nexus-Session Hall shows 50 people in Book a Room tab
- [ ] Indus-Board Room shows 25 people in Book a Room tab
- [ ] Nexus-Session Hall shows 50 people in Room Displays tab
- [ ] Indus-Board Room shows 25 people in Room Displays tab
- [ ] Capacities show correctly in fullscreen preview

---

## Test 3: Admin User Management (10 min)

### **Prerequisites**
- Logged in as admin (muzammil@nic.com)
- At least one startup user exists in system

### **Test 3A: Edit Startup User (5 min)**

**Steps:**
```
1. Go to "Contact Us" tab
2. Scroll down to "Registered Startups" section
3. Find any startup user card
4. Look for "Edit" button (yellow, with pencil icon)
5. Click "Edit" button
```

**Expected: Modal Opens**
```
┌─────────────────────────────────────┐
│ Edit Startup User              [X]  │
├─────────────────────────────────────┤
│                                     │
│ Startup Name:                       │
│ [Tech Startup            ]          │
│                                     │
│ Contact Person:                     │
│ [John Doe                ]          │
│                                     │
│ Email:                              │
│ [john@techstartup.com    ]          │
│                                     │
│ Phone:                              │
│ [+92 300 1234567         ]          │
│                                     │
│         [Cancel]  [Save Changes]    │
└─────────────────────────────────────┘
```

**VERIFY:**
- [ ] Modal opens
- [ ] All fields are pre-filled with current data
- [ ] Fields are editable

**Edit and Save:**
```
6. Change "Startup Name" to "Test Startup UPDATED"
7. Change "Contact Person" to "Jane Doe UPDATED"
8. Click "Save Changes"
```

**Expected: Success**
```
✅ Success message appears: "Startup profile updated successfully"
✅ Modal closes automatically
✅ Startup card shows updated name: "Test Startup UPDATED"
✅ Contact person shows: "Jane Doe UPDATED"
```

**VERIFY:**
- [ ] Success message appears
- [ ] Modal closes
- [ ] Card shows updated information
- [ ] Refresh page (F5) - changes persist

**Console Output:**
```
Open browser console (F12) and verify:
🔄 [editStartupUser] Loading startup abc-123...
✅ [editStartupUser] Startup loaded: {...}
🔄 [saveStartupUserChanges] Updating startup abc-123...
✅ [saveStartupUserChanges] Startup updated successfully
```

---

### **Test 3B: Delete Startup User (5 min)**

**⚠️ WARNING: This will permanently delete a startup user!**
**Use a test startup or create one first.**

**Steps:**
```
1. Go to "Contact Us" tab
2. Find a TEST startup user card
3. Look for "Delete" button (red, with trash icon)
4. Click "Delete" button
```

**Expected: Confirmation Dialog**
```
┌─────────────────────────────────────┐
│ Are you sure you want to delete     │
│ "Test Startup"?                     │
│                                     │
│ This will:                          │
│ - Delete the startup profile        │
│ - Remove all associated bookings    │
│ - This action cannot be undone      │
│                                     │
│ Type the startup name to confirm    │
│ deletion.                           │
│                                     │
│         [Cancel]  [OK]              │
└─────────────────────────────────────┘
```

**VERIFY:**
- [ ] Confirmation dialog appears
- [ ] Dialog shows startup name
- [ ] Dialog warns about permanent deletion

**Confirm Deletion:**
```
5. Click "OK"
```

**Expected: Name Prompt**
```
┌─────────────────────────────────────┐
│ Please type "Test Startup" to       │
│ confirm deletion:                   │
│                                     │
│ [                        ]          │
│                                     │
│         [Cancel]  [OK]              │
└─────────────────────────────────────┘
```

**VERIFY:**
- [ ] Prompt asks to type startup name
- [ ] Exact name is required

**Type Name and Confirm:**
```
6. Type "Test Startup" (exact match)
7. Click "OK"
```

**Expected: Success**
```
✅ Success message: "Startup 'Test Startup' deleted successfully"
✅ Startup card is removed from list
✅ List reloads without deleted startup
```

**VERIFY:**
- [ ] Success message appears
- [ ] Card is removed immediately
- [ ] Refresh page (F5) - startup is still deleted

**Console Output:**
```
🔄 [deleteStartupUser] Deleting startup abc-123...
🔄 [deleteStartupUser] Deleting from database...
✅ [deleteStartupUser] Startup deleted successfully
```

---

### **Test 3C: Cancel Operations (2 min)**

**Test Cancel Edit:**
```
1. Click "Edit" button on any startup
2. Modal opens
3. Change some fields
4. Click "Cancel" button
5. VERIFY: Modal closes
6. VERIFY: No changes were saved
```

**Test Cancel Delete:**
```
1. Click "Delete" button on any startup
2. Confirmation dialog appears
3. Click "Cancel"
4. VERIFY: Dialog closes
5. VERIFY: Startup still exists
```

**Test Wrong Name on Delete:**
```
1. Click "Delete" button
2. Click "OK" on confirmation
3. Type wrong name (e.g., "Wrong Name")
4. Click "OK"
5. VERIFY: Error message appears
6. VERIFY: Startup is NOT deleted
```

---

## Success Checklist

### **FIX 1: Room Duration Display**
- [ ] Indus-Board Room shows "8 hours max"
- [ ] Nexus-Session Hall shows "8 hours max"
- [ ] Podcast Room shows "8 hours max"
- [ ] HUB (Focus Room) shows "2 hours max"
- [ ] Other focus rooms show "2 hours max"

### **FIX 2: Room Capacity Display**
- [ ] SQL script runs successfully
- [ ] Nexus-Session Hall shows 50 people (Book a Room)
- [ ] Nexus-Session Hall shows 50 people (Room Displays)
- [ ] Nexus-Session Hall shows 50 people (Fullscreen)
- [ ] Indus-Board Room shows 25 people (Book a Room)
- [ ] Indus-Board Room shows 25 people (Room Displays)
- [ ] Indus-Board Room shows 25 people (Fullscreen)

### **FIX 3: Admin User Management**
- [ ] Edit button visible on startup cards (admin only)
- [ ] Delete button visible on startup cards (admin only)
- [ ] Edit modal opens with pre-filled data
- [ ] Edit saves changes to database
- [ ] Edit shows success message
- [ ] Edit reloads data automatically
- [ ] Delete shows confirmation dialog
- [ ] Delete requires typing exact name
- [ ] Delete removes startup from database
- [ ] Delete shows success message
- [ ] Delete reloads data automatically
- [ ] Cancel buttons work correctly
- [ ] All changes persist after refresh

---

## Troubleshooting

### **Issue: Room duration still shows 2 hours**

**Solution:**
- Hard refresh (Ctrl+Shift+R)
- Clear browser cache
- Check console for errors

### **Issue: Room capacity not updated**

**Solution:**
- Make sure SQL script ran successfully
- Check Supabase SQL Editor for errors
- Hard refresh application
- Check console for errors

### **Issue: Edit/Delete buttons not visible**

**Solution:**
- Make sure you're logged in as admin
- Check currentUser.role === 'admin'
- Hard refresh application
- Check console for errors

### **Issue: Edit modal not opening**

**Solution:**
- Check console for errors
- Verify `window.editStartupUser` is defined
- Hard refresh application

### **Issue: Delete not working**

**Solution:**
- Make sure you typed exact startup name
- Check console for errors
- Verify database permissions
- Check Supabase RLS policies

---

## Quick Summary

**Testing Time:** ~15 minutes total

**What to Test:**
1. ✅ Room duration display (2 min)
2. ✅ Room capacity display (3 min)
3. ✅ Admin user management (10 min)

**Files to Check:**
- `index.html` (modified)
- `UPDATE-ROOM-CAPACITIES.sql` (run in Supabase)

**Expected Results:**
- ✅ 3 rooms show 8 hours max duration
- ✅ 2 rooms show correct capacities (50 and 25)
- ✅ Admins can edit and delete startup users

---

## 🎉 **Ready to Test!**

1. **Reload the application** (F5)
2. **Run the SQL script** in Supabase
3. **Test all three fixes** (~15 minutes)
4. **Check all items** in Success Checklist
5. **Report any issues** with console logs

See **THREE-FIXES-COMPLETE.md** for complete technical details.

---

**All three fixes are implemented and ready to test!** 🚀

