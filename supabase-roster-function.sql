-- Run this once in Supabase SQL Editor after supabase-schema.sql succeeds.
drop function if exists public.get_class_roster(text);`r`ncreate or replace function public.get_class_roster(p_password text, p_student_id text default '')
returns table(student_id text, name text, gender text, phone text, dorm text, can_edit boolean)
language sql
security definer
set search_path=public
as $$
  select s.student_id, s.name, s.gender, s.phone, s.dorm, p_student_id = '26050008'
  from public.class_students s
  cross join public.class_settings c
  where extensions.crypt(p_password, c.password_hash) = c.password_hash
  order by s.student_id;
$$;

revoke all on function public.get_class_roster(text,text) from public;
grant execute on function public.get_class_roster(text,text) to anon, authenticated;

create or replace function public.update_roster_contact(p_password text,p_actor_id text,p_student_id text,p_phone text,p_dorm text)
returns boolean language plpgsql security definer set search_path=public as $$
begin
  if p_actor_id <> '26050008' then return false; end if;
  if not exists(select 1 from public.class_settings where extensions.crypt(p_password,password_hash)=password_hash) then return false; end if;
  update public.class_students set phone=coalesce(p_phone,''), dorm=coalesce(p_dorm,''), updated_at=now() where student_id=p_student_id;
  return found;
end;
$$;
revoke all on function public.update_roster_contact(text,text,text,text,text) from public;
grant execute on function public.update_roster_contact(text,text,text,text,text) to anon, authenticated;
