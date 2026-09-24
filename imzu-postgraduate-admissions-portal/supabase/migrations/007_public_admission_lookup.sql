-- Read-only public lookup for the matriculation-number verification form.
-- It accepts both the matriculation number and degree level; it never writes data.

create or replace function public.check_admission_status(
  p_matriculation_number text,
  p_programme text
)
returns table (
  full_name text,
  programme_name text,
  session text,
  status text
)
language sql
security definer
set search_path = public
as $$
  select a.full_name, d.programme_name, d.session, d.status
  from public.applicants a
  join public.admissions d on d.applicant_id = a.id
  where upper(trim(a.matriculation_number)) = upper(trim(p_matriculation_number))
    and a.programme_level = case trim(p_programme)
      when 'Postgraduate Diploma (PGD)' then 'PGD'
      when 'Master''s Degree' then 'Masters'
      when 'Doctor of Philosophy (Ph.D.)' then 'PhD'
      else trim(p_programme)
    end;
$$;

revoke all on function public.check_admission_status(text, text) from public;
grant execute on function public.check_admission_status(text, text) to anon, authenticated;
