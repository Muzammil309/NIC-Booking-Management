# Real-Time Status Sync - Quick Testing Guide 🧪

## Quick Test (5 Minutes)

This guide will help you verify that the automatic room status synchronization is working correctly.

---

## Prerequisites ✅

1. **Browser:** Chrome, Firefox, or Edge
2. **Console Open:** Press F12 → Console tab
3. **Logged In:** As admin or startup user
4. **Current Time:** Note your current time

---

## Test 1: Verify Auto-Sync is Running (1 min) ⏰

### **Steps:**

```
1. Open browser console (F12)
2. Refresh the page (Ctrl+R)
3. Look for initialization logs
```

### **Expected Console Output:**

```
🚀 [INITIALIZATION] Setting up automatic room status synchronization...
⏰ [INITIALIZATION] Sync interval: 60 seconds (1 minute)
📊 [INITIALIZATION] Will check booking times against current time
🔄 [INITIALIZATION] Will auto-update: Available ↔ Occupied ↔ Reserved
⚠️ [INITIALIZATION] Maintenance status is protected (admin override)
✅ [INITIALIZATION] Room status sync scheduled successfully!
✅ [INITIALIZATION] Sync will run every 60 seconds automatically

🔄 [syncRoomStatusWithBookings] ========== STARTING SYNC ==========
📅 [syncRoomStatusWithBookings] Current date: 2025-10-01
⏰ [syncRoomStatusWithBookings] Current time: 14:30 (10/1/2025, 2:30:00 PM)
📊 [syncRoomStatusWithBookings] Found 9 rooms to check
📊 [syncRoomStatusWithBookings] Found X confirmed bookings for today
```

### **✅ Pass Criteria:**
- Initialization logs appear
- Sync starts immediately
- Shows current date and time
- Shows number of rooms and bookings

### **❌ If Failed:**
- Hard refresh browser (Ctrl+Shift+R)
- Check for JavaScript errors in console
- Verify you're on the latest version of index.html

---

## Test 2: Create Test Booking (2 min) 📅

### **Steps:**

```
1. Note current time (e.g., 2:30 PM)
2. Go to "Book a Room" tab
3. Create a booking:
   - Room: Hub (or any available room)
   - Date: Today
   - Start Time: 2 minutes from now (e.g., 2:32 PM)
   - Duration: 1 hour
4. Submit booking
5. Wait for confirmation
```

### **Expected Result:**

```
✅ Booking created successfully
📅 Booking details:
   - Room: Hub
   - Date: 2025-10-01
   - Time: 14:32 - 15:32
   - Duration: 1 hour
```

### **Console Output:**

```
✅ [createBooking] Booking created successfully
🔄 [syncRoomStatusWithBookings] Starting sync...
📅 Room is RESERVED (has upcoming booking)
```

---

## Test 3: Verify Status Changes to Reserved (1 min) 📋

### **Steps:**

```
1. Go to "Room Displays" tab
2. Find the room you booked (Hub)
3. Check the status badge
```

### **Expected Status:**

```
Status: RESERVED (yellow badge)
Reason: Has upcoming booking in 2 minutes
```

### **Console Output (within 60 seconds):**

```
🔍 [syncRoomStatusWithBookings] Checking room: Hub (current status: available)
   📋 Found 1 booking(s) for this room
   📅 Upcoming booking found: 14:32
   📅 Room is RESERVED (has upcoming booking)
   🔄 STATUS CHANGE DETECTED: available → reserved
   ✅ Rooms table updated successfully
   ✅ Room_displays table updated successfully
```

---

## Test 4: Verify Status Changes to Occupied (2 min) ⏰

### **Steps:**

```
1. Wait until booking start time (e.g., 2:32 PM)
2. Watch the console
3. Within 60 seconds, you should see status change
4. Check Room Displays tab
```

### **Expected Status:**

```
Status: OCCUPIED (red badge)
Reason: Booking is now active
```

### **Console Output (at or after 2:32 PM):**

```
🔍 [syncRoomStatusWithBookings] Checking room: Hub (current status: reserved)
   📋 Found 1 booking(s) for this room
   ⏰ Checking booking: 14:32 - 15:32
      Current time: 14:32
      Is active? true
   ✅ ACTIVE BOOKING FOUND! Room is OCCUPIED
      Booking: 14:32 - 15:32 (1h)
   🔄 STATUS CHANGE DETECTED: reserved → occupied
   ✅ Rooms table updated successfully
   ✅ Room_displays table updated successfully
```

### **UI Verification:**

```
1. Room card shows "OCCUPIED" badge (red)
2. Click "Click to preview" on the room
3. Preview modal shows:
   - Large "OCCUPIED" status
   - Current booking details
   - End time countdown
```

---

## Test 5: Verify UI Auto-Refresh (1 min) 🔄

### **Steps:**

```
1. Stay on Room Displays tab
2. Don't refresh the page manually
3. Watch the console
4. Wait 30 seconds
```

### **Expected Console Output:**

```
🔄 [Auto-Refresh] Refreshing Room Displays tab...
✅ [Auto-Refresh] Room Displays tab refreshed
```

### **Expected Behavior:**

```
- Room cards refresh automatically
- Status badges update without page reload
- No manual refresh needed
```

---

## Test 6: Verify Status Changes to Available (Optional - 1 hour) ⏳

**Note:** This test requires waiting for the booking to end.

### **Steps:**

```
1. Wait until booking end time (e.g., 3:32 PM)
2. Watch the console
3. Within 60 seconds after end time, status should change
```

### **Expected Console Output:**

```
🔍 [syncRoomStatusWithBookings] Checking room: Hub (current status: occupied)
   📋 Found 1 booking(s) for this room
   ⏰ Checking booking: 14:32 - 15:32
      Current time: 15:32
      Is active? false
   ✅ Room is AVAILABLE (no bookings)
   🔄 STATUS CHANGE DETECTED: occupied → available
   ✅ Rooms table updated successfully
   ✅ Room_displays table updated successfully
```

### **Expected Status:**

```
Status: AVAILABLE (green badge)
Reason: Booking has ended
```

---

## Test 7: Verify Maintenance Override (1 min) 🔧

### **Steps:**

```
1. Go to Room Displays tab
2. Click "Configure" on any room
3. Change "Current Status" to "Maintenance"
4. Save changes
5. Wait 60 seconds
6. Check console
```

### **Expected Console Output:**

```
🔍 [syncRoomStatusWithBookings] Checking room: Hub (current status: maintenance)
   ⚠️ Room is in MAINTENANCE - skipping auto-sync (admin override)
```

### **Expected Behavior:**

```
- Room stays in "Maintenance" status
- Auto-sync skips this room
- Status does NOT change even if there are bookings
```

### **Cleanup:**

```
1. Click "Configure" again
2. Change status back to "Available"
3. Save changes
```

---

## Quick Verification Checklist ✅

After running all tests, verify:

- [ ] Auto-sync initializes on page load
- [ ] Sync runs every 60 seconds
- [ ] Status changes: Available → Reserved (before booking)
- [ ] Status changes: Reserved → Occupied (at booking start)
- [ ] Status changes: Occupied → Available (at booking end)
- [ ] UI auto-refreshes every 30 seconds
- [ ] Maintenance status is protected
- [ ] Console logs are detailed and clear
- [ ] No JavaScript errors in console
- [ ] Database updates successfully

---

## Expected Timeline Example 📊

**Scenario:** Booking from 2:32 PM to 3:32 PM

| Time | Room Status | Reason | Console Log |
|------|-------------|--------|-------------|
| 2:30 PM | Available | No bookings | "Room is AVAILABLE" |
| 2:31 PM | Reserved | Upcoming booking | "Room is RESERVED" |
| 2:32 PM | Occupied | Booking started | "ACTIVE BOOKING FOUND" |
| 2:33 PM | Occupied | Still in booking | "Room is OCCUPIED" |
| 3:31 PM | Occupied | Still in booking | "Room is OCCUPIED" |
| 3:32 PM | Available | Booking ended | "Room is AVAILABLE" |

---

## Troubleshooting 🔧

### **Sync Not Running?**

**Symptoms:**
- No sync logs in console
- Status not updating

**Solutions:**
1. Hard refresh (Ctrl+Shift+R)
2. Check for JavaScript errors
3. Verify Supabase connection
4. Check browser console for errors

---

### **Status Not Changing?**

**Symptoms:**
- Sync runs but status stays the same
- Console shows "No status change needed"

**Check:**
1. Verify booking time is correct
2. Check current time on computer
3. Verify booking status is "confirmed"
4. Check if room is in "Maintenance"

**Console Should Show:**
```
🔄 STATUS CHANGE DETECTED: available → occupied
```

---

### **UI Not Refreshing?**

**Symptoms:**
- Status changes in database but not in UI
- Need to manually refresh page

**Solutions:**
1. Verify you're on Room Displays tab
2. Check for auto-refresh logs
3. Hard refresh browser
4. Check network connection

**Console Should Show:**
```
🔄 [Auto-Refresh] Refreshing Room Displays tab...
```

---

## Success Criteria ✅

**All tests pass if:**

1. ✅ Initialization logs appear on page load
2. ✅ Sync runs every 60 seconds automatically
3. ✅ Status changes from Available → Reserved before booking
4. ✅ Status changes from Reserved → Occupied at booking start
5. ✅ Status changes from Occupied → Available at booking end
6. ✅ UI refreshes every 30 seconds without manual refresh
7. ✅ Maintenance status is protected from auto-sync
8. ✅ Console logs are detailed and informative
9. ✅ No errors in console
10. ✅ Database updates successfully

---

## Quick Test Summary

**Total Time:** ~5-10 minutes (excluding waiting for booking to end)

**Steps:**
1. Verify auto-sync initialization (1 min)
2. Create test booking (2 min)
3. Verify Reserved status (1 min)
4. Verify Occupied status (2 min)
5. Verify UI auto-refresh (1 min)
6. Verify Maintenance override (1 min)

**Expected Result:**
- All status transitions work automatically
- UI updates without manual refresh
- Console logs provide clear feedback
- System is production-ready

---

**Happy Testing! 🎉**

The real-time status synchronization is fully functional and ready for production use!

