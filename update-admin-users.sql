-- Ensure admin@nic.com has role 'admin' in public.users (synced from auth.users)
-- 1) Create/Update profile row for admin@nic.com
INSERT INTO public.users (id, email, name, role)
SELECT au.id, au.email, COALESCE(au.raw_user_meta_data->>'name','Admin'), 'admin'
FROM auth.users au
WHERE au.email = 'admin@nic.com'
ON CONFLICT (id) DO UPDATE SET role = EXCLUDED.role;

-- 2) Verify
SELECT id, email, role FROM public.users WHERE email='admin@nic.com';

