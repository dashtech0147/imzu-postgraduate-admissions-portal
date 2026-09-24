This repository is a software template. “IMSU” names, logos, and branding remain the property of their respective owners and are not granted for reuse by this license.

# IMSU Postgraduate Admissions Portal

Static, responsive portal prototype for postgraduate admission verification and applicant login.

## Run locally

Open `index.html` directly in a browser, or serve the directory with any static web server.

## Supabase setup

1. In Supabase Dashboard, open **SQL Editor**, create a new query, paste and run `supabase/migrations/001_admissions_schema.sql`.
2. For the **Doctorate/PhD** label and professional-course support, paste and run `supabase/migrations/008_doctorate_phd_courses.sql` once. It only adds the Doctorate course table and replaces the lookup function; it does not update or delete PGD, Master's, or existing admission records.
3. Use a server-side admin job—not the browser—to create applicant accounts and insert admission records.
4. The browser only uses the Supabase publishable key. Do not add a secret/service-role key to this project.

## Adding a Doctorate/PhD professional course

After the applicant and admission record have been created, run the commented `insert into public.doctorate_professional_courses` statement at the bottom of `supabase/migrations/008_doctorate_phd_courses.sql`, replacing the applicant UUID and course. Accepted values are `PsyD`, `EdD`, `ThD`, `MD`, `EngD`, `JD`, and `DNP`. This table is separate from PGD and Master's records; the admission-status result shows the course only when one is set.

## Adding applicants

Use `supabase/migrations/009_add_student_template.sql` for every new student—PGD, Master's Degree, or Doctorate/PhD. Replace the values in its `DECLARE` block, select the programme level, then run it once per student. Leave `v_professional_course` as `null` for PGD and Master's students; select one accepted course for Doctorate/PhD students. The student's Supabase Auth account must exist first, because the query verifies the UUID and email before making any changes.

## Production work remaining

The applicant login is connected to Supabase Auth. Before launch, add the authenticated admission-decision screen, a server-side applicant-import process, authentication rate limits, bot protection, audit logs, and a custom SMTP provider.
