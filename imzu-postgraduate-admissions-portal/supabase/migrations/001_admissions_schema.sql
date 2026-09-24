-- Run once in Supabase Dashboard > SQL Editor > New query.
-- This creates private, applicant-owned records. No admission data is public.

create table if not exists public.applicants (
  id uuid primary key references auth.users(id) on delete cascade,
  application_number text not null unique check (application_number ~ '^IMSU/PG/[0-9]{2}/[0-9]{5}$'),
  full_name text not null,
  programme_level text not null check (programme_level in ('PGD', 'Masters', 'PhD')),
  created_at timestamptz not null default now()
);

create table if not exists public.admissions (
  id uuid primary key default gen_random_uuid(),
  applicant_id uuid not null unique references public.applicants(id) on delete cascade,
  status text not null check (status in ('pending', 'admitted', 'not_admitted')) default 'pending',
  programme_name text not null,
  session text not null default '2025/2026',
  decision_published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.applicants enable row level security;
alter table public.admissions enable row level security;

drop policy if exists "Applicants read own profile" on public.applicants;
create policy "Applicants read own profile" on public.applicants
  for select to authenticated using ((select auth.uid()) = id);

drop policy if exists "Applicants read own admission" on public.admissions;
create policy "Applicants read own admission" on public.admissions
  for select to authenticated using ((select auth.uid()) = applicant_id);

-- No write policies are created. Writes must use a server-side admin process,
-- never a browser or publishable key.
