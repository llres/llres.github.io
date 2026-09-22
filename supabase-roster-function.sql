-- Run this once in Supabase SQL Editor after supabase-schema.sql succeeds.
create or replace function public.get_class_roster(p_password text)
returns table(student_id text, name text, gender text)
language sql
security definer
set search_path=public
as $$
  select s.student_id, s.name, s.gender
  from public.class_students s
  cross join public.class_settings c
  where extensions.crypt(p_password, c.password_hash) = c.password_hash
  order by s.student_id;
$$;

revoke all on function public.get_class_roster(text) from public;
grant execute on function public.get_class_roster(text) to anon, authenticated;
