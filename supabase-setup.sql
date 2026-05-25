-- jziyy cloud album setup
-- Run this in Supabase SQL Editor for the project that will store the shared albums.

create extension if not exists pgcrypto;

create table if not exists public.albums (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  note text default '',
  tone integer default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.photos (
  id uuid primary key default gen_random_uuid(),
  album_id uuid not null references public.albums(id) on delete cascade,
  name text default '',
  path text not null,
  created_at timestamptz not null default now()
);

alter table public.albums enable row level security;
alter table public.photos enable row level security;

drop policy if exists "jziyy albums read" on public.albums;
drop policy if exists "jziyy albums insert" on public.albums;
drop policy if exists "jziyy albums update" on public.albums;
drop policy if exists "jziyy albums delete" on public.albums;
drop policy if exists "jziyy photos read" on public.photos;
drop policy if exists "jziyy photos insert" on public.photos;
drop policy if exists "jziyy photos delete" on public.photos;

create policy "jziyy albums read" on public.albums for select to anon using (true);
create policy "jziyy albums insert" on public.albums for insert to anon with check (true);
create policy "jziyy albums update" on public.albums for update to anon using (true) with check (true);
create policy "jziyy albums delete" on public.albums for delete to anon using (true);

create policy "jziyy photos read" on public.photos for select to anon using (true);
create policy "jziyy photos insert" on public.photos for insert to anon with check (true);
create policy "jziyy photos delete" on public.photos for delete to anon using (true);

grant select, insert, update, delete on public.albums to anon;
grant select, insert, delete on public.photos to anon;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'jziyy-photos',
  'jziyy-photos',
  true,
  12582912,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "jziyy photos public read" on storage.objects;
drop policy if exists "jziyy photos public upload" on storage.objects;
drop policy if exists "jziyy photos public delete" on storage.objects;

create policy "jziyy photos public read"
on storage.objects for select to anon
using (bucket_id = 'jziyy-photos');

create policy "jziyy photos public upload"
on storage.objects for insert to anon
with check (bucket_id = 'jziyy-photos');

create policy "jziyy photos public delete"
on storage.objects for delete to anon
using (bucket_id = 'jziyy-photos');
