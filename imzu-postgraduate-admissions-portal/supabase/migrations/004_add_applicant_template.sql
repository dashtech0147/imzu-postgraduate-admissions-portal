-- Reusable admin-only import template.
-- Replace the values in the DECLARE block, then run one applicant at a time.
-- Do not run this unchanged. Do not put passwords in this query.

do $$
declare
  v_uid uuid := 'REPLACE-WITH-AUTH-USER-UUID'::uuid;
  v_email text := 'replace@example.com';
  v_full_name text := 'REPLACE WITH FULL NAME';
  v_matriculation_number text := 'REPLACE-MATRIC-NUMBER';
  v_programme_level text := 'MSc'; -- PGD, MSc, Masters, or PhD
  v_programme_name text := 'Public Health';
  v_session text := '2024/2025';
  v_status text := 'pending'; -- pending, admitted, or not_admitted
begin
  if not exists (
    select 1 from auth.users
    where id = v_uid and lower(email) = lower(v_email)
  ) then
    raise exception 'Auth user UID and email do not match; create the Auth user first';
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
end $$;
