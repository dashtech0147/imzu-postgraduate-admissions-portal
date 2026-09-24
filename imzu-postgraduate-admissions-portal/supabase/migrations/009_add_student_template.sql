-- ADD ONE APPLICANT: PGD, Master's Degree, or Doctorate/PhD.
-- Run this in Supabase Dashboard > SQL Editor after creating the student's
-- Supabase Auth account. Replace every REPLACE value before running.
-- Run this same query once for each student. It changes only the student whose
-- UUID you enter; it does not change any other applicant's admission record.

do $$
declare
  v_uid uuid := 'REPLACE-APPLICANT-UUID'::uuid;
  v_email text := 'student@example.com';
  v_full_name text := 'REPLACE WITH STUDENT FULL NAME';
  v_matriculation_number text := 'REPLACE-MATRICULATION-NUMBER';
  v_programme text := 'Postgraduate Diploma (PGD)';
  -- Choose exactly one:
  -- 'Postgraduate Diploma (PGD)'
  -- 'Master''s Degree'
  -- 'Doctorate/PhD'
  v_programme_name text := 'REPLACE WITH COURSE/PROGRAMME NAME';
  v_professional_course text := null;
  -- Leave as null for PGD and Master's Degree.
  -- For Doctorate/PhD, use exactly one: PsyD, EdD, ThD, MD, EngD, JD, or DNP.
  v_session text := '2025/2026';
  v_status text := 'pending'; -- pending, admitted, or not_admitted
  v_programme_level text;
begin
  v_programme_level := case v_programme
    when 'Postgraduate Diploma (PGD)' then 'PGD'
    when 'Master''s Degree' then 'Masters'
    when 'Doctorate/PhD' then 'PhD'
    else null
  end;

  if v_programme_level is null then
    raise exception 'Programme must be Postgraduate Diploma (PGD), Master''s Degree, or Doctorate/PhD';
  end if;

  if v_status not in ('pending', 'admitted', 'not_admitted') then
    raise exception 'Status must be pending, admitted, or not_admitted';
  end if;

  if v_programme_level = 'PhD'
    and (v_professional_course is null
      or v_professional_course not in ('PsyD', 'EdD', 'ThD', 'MD', 'EngD', 'JD', 'DNP')) then
    raise exception 'Doctorate/PhD requires PsyD, EdD, ThD, MD, EngD, JD, or DNP as the professional course';
  end if;

  if v_programme_level <> 'PhD' and v_professional_course is not null then
    raise exception 'Professional course must be null for PGD and Master''s Degree applicants';
  end if;

  if not exists (
    select 1 from auth.users
    where id = v_uid and lower(email) = lower(v_email)
  ) then
    raise exception 'The Auth user UUID and email do not match. Create the student Auth account first.';
  end if;

  insert into public.applicants (
    id, matriculation_number, full_name, programme_level, academic_session
  ) values (
    v_uid, v_matriculation_number, v_full_name, v_programme_level, v_session
  )
  on conflict (id) do update set
    matriculation_number = excluded.matriculation_number,
    full_name = excluded.full_name,
    programme_level = excluded.programme_level,
    academic_session = excluded.academic_session;

  insert into public.admissions (
    applicant_id, status, programme_name, session
  ) values (
    v_uid, v_status, v_programme_name, v_session
  )
  on conflict (applicant_id) do update set
    status = excluded.status,
    programme_name = excluded.programme_name,
    session = excluded.session,
    updated_at = now();

  if v_programme_level = 'PhD' then
    insert into public.doctorate_professional_courses (
      applicant_id, professional_course
    ) values (
      v_uid, v_professional_course
    )
    on conflict (applicant_id) do update set
      professional_course = excluded.professional_course,
      updated_at = now();
  else
    -- Removes a course only for this same applicant if their level is changed.
    delete from public.doctorate_professional_courses where applicant_id = v_uid;
  end if;
end $$;
