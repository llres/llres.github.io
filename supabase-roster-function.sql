-- Run this after supabase-schema.sql. Only student 26050008 can write.
drop function if exists public.get_class_roster(text);
drop function if exists public.get_class_roster(text,text);
create or replace function public.get_class_roster(p_password text,p_student_id text default '')
returns table(student_id text,name text,gender text,phone text,dorm text)
language sql security definer set search_path=public as $$
  select s.student_id,s.name,s.gender,s.phone,s.dorm from public.class_students s
  cross join public.class_settings c
  where extensions.crypt(p_password,c.password_hash)=c.password_hash
  order by s.student_id;
$$;
create or replace function public.admin_upsert_student(p_password text,p_actor_id text,p_old_student_id text,p_student_id text,p_name text,p_gender text,p_phone text,p_dorm text)
returns boolean language plpgsql security definer set search_path=public as $$
begin
  if p_actor_id<>'26050008' or not exists(select 1 from public.class_students where student_id='26050008') then return false; end if;
  if not exists(select 1 from public.class_settings where extensions.crypt(p_password,password_hash)=password_hash) then return false; end if;
  if p_old_student_id is not null and p_old_student_id<>'' and p_old_student_id<>p_student_id then
    update public.class_students set student_id=p_student_id,name=p_name,gender=p_gender,phone=coalesce(p_phone,''),dorm=coalesce(p_dorm,''),updated_at=now() where student_id=p_old_student_id;
  else
    insert into public.class_students(student_id,name,gender,phone,dorm) values(p_student_id,p_name,p_gender,coalesce(p_phone,''),coalesce(p_dorm,'')) on conflict(student_id) do update set name=excluded.name,gender=excluded.gender,phone=excluded.phone,dorm=excluded.dorm,updated_at=now();
  end if;
  return found;
end;
$$;
create or replace function public.admin_delete_student(p_password text,p_actor_id text,p_student_id text)
returns boolean language plpgsql security definer set search_path=public as $$
begin
  if p_actor_id<>'26050008' or p_student_id='26050008' then return false; end if;
  if not exists(select 1 from public.class_settings where extensions.crypt(p_password,password_hash)=password_hash) then return false; end if;
  delete from public.class_students where student_id=p_student_id; return found;
end;
$$;
revoke all on function public.get_class_roster(text,text) from public;
revoke all on function public.admin_upsert_student(text,text,text,text,text,text,text,text) from public;
revoke all on function public.admin_delete_student(text,text,text) from public;
grant execute on function public.get_class_roster(text,text) to anon,authenticated;
grant execute on function public.admin_upsert_student(text,text,text,text,text,text,text,text) to anon,authenticated;
grant execute on function public.admin_delete_student(text,text,text) to anon,authenticated;
