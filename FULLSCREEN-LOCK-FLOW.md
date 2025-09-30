# Room Display Fullscreen Lock - Security Flow

## Overview
This document explains how the fullscreen password lock works to prevent unauthorized users from tampering with physical room display screens.

---

## Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    USER OPENS ROOM PREVIEW                       │
│                  (Admin clicks on room card)                     │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                   PREVIEW MODAL OPENS                            │
│         Shows room status, bookings, and controls                │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│              USER CLICKS "FULLSCREEN" BUTTON                     │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                  ENTERS FULLSCREEN MODE                          │
│              isFullscreenLocked = true                           │
│         Display shows: "Password required to exit"               │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                 USER ATTEMPTS TO EXIT                            │
│         (ESC key, close button, or browser controls)             │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
                    ┌────────┴────────┐
                    │  Check User Role │
                    └────────┬────────┘
                             │
              ┌──────────────┴──────────────┐
              │                             │
              ▼                             ▼
    ┌─────────────────┐         ┌─────────────────────┐
    │   ADMIN USER    │         │  NON-ADMIN USER     │
    │                 │         │  (Startup/Guest)    │
    └────────┬────────┘         └──────────┬──────────┘
             │                              │
             ▼                              ▼
┌────────────────────────┐    ┌────────────────────────────────┐
│ Simple Confirmation    │    │  PASSWORD PROMPT               │
│ "Exit fullscreen?"     │    │  "🔒 DISPLAY LOCKED"           │
│                        │    │  "Enter admin password"        │
└────────┬───────────────┘    └──────────┬─────────────────────┘
         │                               │
         │ Click OK                      │ Enter Password
         │                               │
         ▼                               ▼
┌────────────────────────┐    ┌────────────────────────────────┐
│  EXIT FULLSCREEN       │    │  VERIFY PASSWORD               │
│  Close modal           │    │  (Check against admin@nic.com) │
└────────────────────────┘    └──────────┬─────────────────────┘
                                         │
                              ┌──────────┴──────────┐
                              │                     │
                              ▼                     ▼
                    ┌──────────────────┐  ┌──────────────────┐
                    │ CORRECT PASSWORD │  │ WRONG PASSWORD   │
                    └────────┬─────────┘  └────────┬─────────┘
                             │                     │
                             ▼                     ▼
                  ┌──────────────────┐  ┌──────────────────────┐
                  │ EXIT FULLSCREEN  │  │ STAY IN FULLSCREEN   │
                  │ Close modal      │  │ Show error message   │
                  │ isFullscreenLocked│  │ Auto re-enter if     │
                  │ = false          │  │ user exits           │
                  └──────────────────┘  └──────────────────────┘
```

---

## Security Mechanisms

### 1. Fullscreen Lock Flag
```javascript
let isFullscreenLocked = false;  // Tracks if display is locked
let fullscreenElement = null;    // Stores the fullscreen element
```

When user enters fullscreen:
```javascript
isFullscreenLocked = true;
```

### 2. Event Monitoring
The system monitors ALL fullscreen change events:
```javascript
document.addEventListener('fullscreenchange', handleFullscreenChange);
document.addEventListener('webkitfullscreenchange', handleFullscreenChange);
document.addEventListener('mozfullscreenchange', handleFullscreenChange);
document.addEventListener('MSFullscreenChange', handleFullscreenChange);
```

### 3. Auto Re-lock Mechanism
If user exits fullscreen without password:
```javascript
async function handleFullscreenChange() {
    const isCurrentlyFullscreen = !!(
        document.fullscreenElement ||
        document.webkitFullscreenElement ||
        // ... other vendor prefixes
    );

    if (isFullscreenLocked && !isCurrentlyFullscreen) {
        const passwordVerified = await verifyAdminPasswordForExit();
        
        if (!passwordVerified) {
            // Re-enter fullscreen automatically
            setTimeout(async () => {
                await fullscreenElement.requestFullscreen();
            }, 100);
        }
    }
}
```

### 4. ESC Key Interception
```javascript
document.addEventListener('keydown', async (e) => {
    if (isFullscreenLocked && e.key === 'Escape') {
        e.preventDefault();        // Block default ESC behavior
        e.stopPropagation();       // Stop event from bubbling
        
        // Require password verification
        const passwordVerified = await verifyAdminPasswordForExit();
        
        if (passwordVerified) {
            // Only exit if password correct
            document.exitFullscreen();
        }
    }
}, true);  // Use capture phase
```

---

## Password Verification Logic

### For Admin Users
```javascript
if (currentUser?.role === 'admin') {
    // Simple confirmation dialog
    return confirm('You are about to exit fullscreen display mode. Continue?');
}
```

### For Non-Admin Users
```javascript
// Require password
const password = prompt(
    '🔒 DISPLAY LOCKED\n\n' +
    'This room display is password protected.\n' +
    'Enter the admin password to exit fullscreen mode:'
);

// Verify against admin account
const { error } = await supabaseClient.auth.signInWithPassword({
    email: 'admin@nic.com',
    password: password
});

return !error;  // Return true if password correct
```

---

## Use Cases

### Use Case 1: Physical Display Screen in Meeting Room
**Scenario**: Admin sets up a display screen showing room booking information

1. Admin opens room preview for "Hingol" room
2. Admin clicks "Fullscreen" button
3. Display enters fullscreen mode on the physical screen
4. Admin leaves the room
5. Display shows current booking, next booking, room status
6. **Security**: If anyone tries to exit fullscreen or navigate away:
   - Password prompt appears
   - Display stays locked until correct password entered
   - Prevents attendees from tampering with the display

### Use Case 2: Tablet Display at Reception
**Scenario**: Tablet at reception showing room availability

1. Admin sets up tablet with room display in fullscreen
2. Tablet is left at reception desk
3. Visitors can see room availability
4. **Security**: Visitors cannot:
   - Exit fullscreen mode
   - Navigate to other pages
   - Access admin functions
   - Close the display
5. Only admin with password can unlock and manage the display

### Use Case 3: Conference Room Display
**Scenario**: Large screen in conference room showing current meeting info

1. Admin opens preview for conference room
2. Enters fullscreen mode
3. Display shows:
   - Current meeting details
   - Next meeting time
   - Room status
4. **Security**: Meeting attendees cannot:
   - See other bookings (privacy)
   - Modify the display
   - Access booking system
   - Exit the display view

---

## Security Features Summary

| Feature | Description | Benefit |
|---------|-------------|---------|
| **Password Lock** | Requires admin password to exit fullscreen | Prevents unauthorized access |
| **Auto Re-lock** | Automatically re-enters fullscreen if exited without password | Ensures display stays locked |
| **ESC Key Block** | Intercepts ESC key and requires password | Prevents easy exit |
| **Modal Close Protection** | Requires password to close modal in fullscreen | Comprehensive protection |
| **Admin Convenience** | Admins get simple confirmation instead of password | Easy for authorized users |
| **Multi-browser Support** | Works on Chrome, Firefox, Safari, Edge | Universal compatibility |
| **Event Monitoring** | Monitors all fullscreen change events | Catches all exit attempts |

---

## Configuration

### Changing Admin Email for Password Verification

By default, the system uses `admin@nic.com` for password verification. To change this:

1. Open `index.html`
2. Find the `verifyAdminPasswordForExit()` function
3. Update the email:

```javascript
const { error } = await supabaseClient.auth.signInWithPassword({
    email: 'your-admin-email@nic.com',  // Change this
    password: password
});
```

### Customizing Password Prompt Message

To change the password prompt message:

```javascript
const password = prompt(
    '🔒 YOUR CUSTOM MESSAGE\n\n' +
    'Your custom instructions here\n' +
    'Enter password:'
);
```

---

## Troubleshooting

### Problem: Fullscreen exits without password prompt
**Possible Causes**:
- User is logged in as admin (admins get confirmation, not password)
- JavaScript error preventing lock mechanism
- Browser doesn't support Fullscreen API

**Solutions**:
- Verify user is NOT logged in as admin
- Check browser console for errors
- Test in different browser

### Problem: Can't exit fullscreen even with correct password
**Possible Causes**:
- Wrong admin email configured
- Admin account doesn't exist
- Password is incorrect

**Solutions**:
- Verify admin account exists in database
- Check admin email in code matches actual admin account
- Reset admin password if needed

### Problem: Auto re-lock not working
**Possible Causes**:
- Browser blocking fullscreen re-entry
- JavaScript error in handleFullscreenChange

**Solutions**:
- Check browser console for errors
- Ensure browser allows fullscreen API
- Test in different browser

---

## Best Practices

1. **Document Admin Password**: Keep admin password documented securely for authorized staff
2. **Test Before Deployment**: Test fullscreen lock on actual display hardware before deploying
3. **Train Staff**: Train staff on how to unlock displays when needed
4. **Regular Testing**: Periodically test the lock mechanism to ensure it's working
5. **Browser Updates**: Keep browsers updated for best Fullscreen API support
6. **Backup Access**: Have multiple admin accounts in case one is locked out

---

## Technical Notes

- The lock mechanism uses browser's native Fullscreen API
- Password verification uses Supabase Auth for security
- Event listeners use capture phase for ESC key to ensure interception
- Auto re-lock has 100ms delay to prevent race conditions
- Compatible with all modern browsers (Chrome, Firefox, Safari, Edge)

