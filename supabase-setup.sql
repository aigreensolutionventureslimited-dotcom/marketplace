-- =========================================================
-- AI GREEN SOLUTIONS MARKETPLACE — SUPABASE SETUP SCRIPT
-- =========================================================
-- HOW TO RUN THIS:
-- 1. Go to your Supabase project: https://supabase.com/dashboard/project/jpaieiwfvjeynrnrwuna
-- 2. Click "SQL Editor" in the left sidebar
-- 3. Click "New query", paste this ENTIRE file, click "Run"
-- 4. Then follow the STORAGE BUCKET steps at the bottom (done in the UI, not SQL)
-- =========================================================

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------
-- PRODUCTS
-- ---------------------------------------------------------
create table if not exists products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text,
  sector text not null,
  origin text,
  price numeric,
  price_unit text default 'Metric Ton',
  moq text,
  purity text,
  moisture text,
  packaging text,
  verified_level text default 'Verified',
  supplier text,
  description text,
  image_url text,
  created_at timestamptz default now()
);

-- ---------------------------------------------------------
-- PRODUCT SIZES / VARIANTS (a product can have many size options)
-- ---------------------------------------------------------
create table if not exists product_sizes (
  id uuid primary key default gen_random_uuid(),
  product_id uuid references products(id) on delete cascade,
  size_label text not null,      -- e.g. "25kg Bag", "50kg Bag", "1 Container (20ft)"
  price numeric,
  stock_qty numeric,
  created_at timestamptz default now()
);

-- ---------------------------------------------------------
-- SELLER VERIFICATION APPLICATIONS
-- ---------------------------------------------------------
create table if not exists sellers (
  id uuid primary key default gen_random_uuid(),
  company_name text not null,
  contact_name text not null,
  email text not null,
  phone text,
  business_type text,
  country text,
  city text,
  license_number text,
  message text,
  document_url text,             -- link to uploaded certificate/license file
  status text not null default 'pending',   -- pending | approved | rejected
  admin_notes text,
  created_at timestamptz default now()
);

-- ---------------------------------------------------------
-- ROW LEVEL SECURITY
-- ---------------------------------------------------------
alter table products enable row level security;
alter table product_sizes enable row level security;
alter table sellers enable row level security;

-- Anyone (site visitors) can VIEW products — needed for the public marketplace page
create policy "Public read products" on products
  for select using (true);

create policy "Public read product_sizes" on product_sizes
  for select using (true);

-- Only a logged-in admin (Supabase Auth user) can add/edit/delete products
create policy "Admin insert products" on products
  for insert to authenticated with check (true);
create policy "Admin update products" on products
  for update to authenticated using (true);
create policy "Admin delete products" on products
  for delete to authenticated using (true);

create policy "Admin insert product_sizes" on product_sizes
  for insert to authenticated with check (true);
create policy "Admin update product_sizes" on product_sizes
  for update to authenticated using (true);
create policy "Admin delete product_sizes" on product_sizes
  for delete to authenticated using (true);

-- Anyone can SUBMIT a seller application (from the public site)
create policy "Public submit seller application" on sellers
  for insert with check (true);

-- Only the admin can VIEW or UPDATE (approve/reject) applications
create policy "Admin read sellers" on sellers
  for select to authenticated using (true);
create policy "Admin update sellers" on sellers
  for update to authenticated using (true);

-- =========================================================
-- STORAGE BUCKETS — do this part in the Supabase Dashboard UI
-- =========================================================
-- Go to "Storage" in the left sidebar and create TWO buckets:
--
--   1) product-images   → toggle "Public bucket" ON
--   2) seller-documents → leave "Public bucket" OFF (private)
--
-- Then come back here and run the policies below.
-- =========================================================

create policy "Public read product images" on storage.objects
  for select using (bucket_id = 'product-images');

create policy "Admin upload product images" on storage.objects
  for insert to authenticated with check (bucket_id = 'product-images');

create policy "Admin update product images" on storage.objects
  for update to authenticated using (bucket_id = 'product-images');

create policy "Admin delete product images" on storage.objects
  for delete to authenticated using (bucket_id = 'product-images');

create policy "Public upload seller documents" on storage.objects
  for insert with check (bucket_id = 'seller-documents');

create policy "Admin read seller documents" on storage.objects
  for select to authenticated using (bucket_id = 'seller-documents');

-- =========================================================
-- LAST STEP — create your admin login
-- =========================================================
-- Go to "Authentication" -> "Users" -> "Add user" (create user)
-- Enter YOUR email + a strong password. This is what you'll use
-- to log into admin.html. Do NOT let anyone else create an account
-- here — this is the only login that unlocks the admin dashboard.
-- =========================================================
