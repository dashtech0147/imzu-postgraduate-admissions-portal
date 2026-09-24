-- Run this once in Supabase Dashboard > SQL Editor.
-- It does not alter or delete existing PGD, Master's, or admission records.

create table if not exists public.doctorate_professional_courses (
  applicant_id uuid primary key references public.applicants(id) on delete cascade,
  professional_course text not null check (
    professional_course in ('PsyD', 'EdD', 'ThD', 'MD', 'EngD', 'JD', 'DNP')
  ),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.doctorate_professional_courses enable row level security;

create or replace function public.ensure_doctorate_course_applicant()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if not exists (
    select 1
    from public.applicants
    where id = new.applicant_id
      and programme_level = 'PhD'
  ) then
    raise exception 'A professional course can only be assigned to a Doctorate/PhD applicant';
  end if;
  return new;
end;
$$;

drop trigger if exists validate_doctorate_course_applicant
  on public.doctorate_professional_courses;
create trigger validate_doctorate_course_applicant
  before insert or update on public.doctorate_professional_courses
  for each row execute function public.ensure_doctorate_course_applicant();

drop policy if exists "Applicants read own doctorate course" on public.doctorate_professional_courses;
create policy "Applicants read own doctorate course"
  on public.doctorate_professional_courses
  for select to authenticated
  using ((select auth.uid()) = applicant_id);

-- The existing function must be dropped because its returned columns now include
-- professional_course. This affects only the public lookup function, not data.
drop function if exists public.check_admission_status(text, text);

create function public.check_admission_status(
  p_matriculation_number text,
  p_programme text
)
returns table (
  full_name text,
  programme_name text,
  session text,
  status text,
  professional_course text
)
language sql
security definer
set search_path = public
as $$
  select
    a.full_name,
    d.programme_name,
    d.session,
    d.status,
    c.professional_course
  from public.applicants a
  join public.admissions d on d.applicant_id = a.id
  left join public.doctorate_professional_courses c on c.applicant_id = a.id
  where upper(trim(a.matriculation_number)) = upper(trim(p_matriculation_number))
    and a.programme_level = case trim(p_programme)
      when 'Postgraduate Diploma (PGD)' then 'PGD'
      when 'Master''s Degree' then 'Masters'
      when 'Doctorate/PhD' then 'PhD'
      -- Keeps old saved links and older versions of the form working.
      when 'Doctor of Philosophy (Ph.D.)' then 'PhD'
      else trim(p_programme)
    end;
$$;

revoke all on function public.check_admission_status(text, text) from public;
grant execute on function public.check_admission_status(text, text) to anon, authenticated;

-- Add or change the professional course for a Doctorate/PhD applicant.
-- Replace the UUID and course, then run this statement for each applicant.
-- The applicant must already exist in public.applicants with programme_level = 'PhD'.
--
-- insert into public.doctorate_professional_courses (applicant_id, professional_course)
-- values ('REPLACE-APPLICANT-UUID'::uuid, 'PsyD')
-- on conflict (applicant_id) do update
-- set professional_course = excluded.professional_course,
--     updated_at = now();
