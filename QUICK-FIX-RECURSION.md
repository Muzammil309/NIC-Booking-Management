# Quick Fix: Infinite Recursion Error

## 🚨 **CRITICAL ERROR**

**Error**: "infinite recursion detected in policy for relation 'users'"

**Cause**: RLS policy queries the same table it's protecting

**Impact**: Schedule, Contact Us, and Room Displays tabs broken

---

## ✅ **Quick Fix (5 minutes)**

### **Step 1: Open Supabase SQL Editor**
1. Go to Supabase Dashboard
2. Click **SQL Editor**
3. Click **New Query**

### **Step 2: Copy and Run This Script**

Open **`FIX-INFINITE-RECURSION-RLS.sql`** and run it in SQL Editor.

Or copy this:

```sql
-- Fix infinite recursion in users policy
DROP POLICY IF EXISTS users_select_all ON public.users;

CREATE POLICY users_select_all ON public.users
FOR SELECT TO authenticated
USING (
    id = auth.uid() OR role = 'admin'
);

-- Create helper function to check if user is admin
CREATE OR REPLACE FUNCTION public.is_current_user_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid() AND role = 'admin'
    );
$$;

GRANT EXECUTE ON FUNCTION public.is_current_user_admin() TO authenticated;

-- Add policy for admins to see all users
CREATE POLICY users_select_all_for_admins ON public.users
FOR SELECT TO authenticated
USING (
    public.is_current_user_admin()
);

-- Fix startups policy
DROP POLICY IF EXISTS startups_select_all ON public.startups;

CREATE POLICY startups_select_all ON public.startups
FOR SELECT TO authenticated
USING (
    user_id = auth.uid() OR public.is_current_user_admin()
);
```

### **Step 3: Verify**

Run this test query:
```sql
SELECT id, name, email, role FROM public.users WHERE role = 'admin';
```

Should return 5 rows without errors.

### **Step 4: Test Application**
1. Reload app (F5)
2. Test Schedule tab ✅
3. Test Contact Us tab ✅
4. Test Room Displays tab ✅

---

## 🎯 **What This Fixes**

**Before**:
- ❌ Schedule tab: infinite recursion error
- ❌ Contact Us tab: infinite recursion error
- ❌ Room Displays tab: error loading

**After**:
- ✅ Schedule tab: loads correctly
- ✅ Contact Us tab: shows all 5 admins
- ✅ Room Displays tab: loads correctly

---

## 🔍 **Why This Works**

**Old Policy (Broken)**:
```sql
EXISTS (SELECT 1 FROM users WHERE ...)  -- ❌ Queries same table!
```

**New Policy (Fixed)**:
```sql
public.is_current_user_admin()  -- ✅ Uses SECURITY DEFINER function
```

**SECURITY DEFINER** bypasses RLS, preventing infinite recursion.

---

## ✅ **Verification Checklist**

- [ ] SQL script ran without errors
- [ ] Test query returns 5 admin users
- [ ] Schedule tab loads
- [ ] Contact Us tab shows all 5 admins
- [ ] Room Displays tab loads
- [ ] No console errors

---

## 🆘 **If Still Broken**

1. Check SQL Editor for errors
2. Verify helper function exists:
   ```sql
   SELECT proname FROM pg_proc WHERE proname = 'is_current_user_admin';
   ```
3. Hard refresh app (Ctrl+Shift+R)
4. Check console (F12) for errors

---

## 📁 **Full Documentation**

See **FIX-INFINITE-RECURSION-GUIDE.md** for complete details.

---

## 🚀 **Summary**

**Problem**: Self-referencing RLS policy → infinite recursion

**Solution**: SECURITY DEFINER helper function → bypasses RLS

**Action**: Run SQL script in Supabase SQL Editor

**Time**: 5 minutes

**Result**: All tabs working ✅

