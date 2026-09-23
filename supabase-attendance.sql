-- 班级考勤共享数据表与 RPC
-- 请在 Supabase SQL Editor 执行一次。
create table if not exists public.class_attendance (
  attendance_date date not null,
  student_id text not null references public.class_students(student_id) on update cascade on delete cascade,
  status text not null check (status in ('出勤','迟到','请假','缺勤')) default '出勤',
  remark text not null default '',
  updated_by text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (attendance_date, student_id)
);

alter table public.class_attendance enable row level security;
revoke all on public.class_attendance from anon,authenticated;

create or replace function public.get_class_attendance(p_password text,p_student_id text,p_date date)
returns table(student_id text,status text,remark text)
language plpgsql security definer set search_path=public as $$
begin
  if public.get_class_role(p_password,p_student_id) not in ('member','admin','super_admin') then return; end if;
  return query select a.student_id,a.status,a.remark from public.class_attendance a where a.attendance_date=p_date order by a.student_id;
end;
$$;

create or replace function public.save_class_attendance(p_password text,p_actor_id text,p_date date,p_records jsonb)
returns boolean language plpgsql security definer set search_path=public as $$
declare r jsonb; actor_role text;
begin
  actor_role:=public.get_class_role(p_password,p_actor_id);
  if actor_role not in ('member','admin','super_admin') then return false; end if;
  if jsonb_typeof(p_records)<>'array' then return false; end if;
  for r in select value from jsonb_array_elements(p_records) loop
    if not exists(select 1 from public.class_students where student_id=r->>'student_id') then continue; end if;
    if (r->>'status') not in ('出勤','迟到','请假','缺勤') then continue; end if;
    insert into public.class_attendance(attendance_date,student_id,status,remark,updated_by,updated_at)
    values(p_date,r->>'student_id',r->>'status',coalesce(r->>'remark',''),p_actor_id,now())
    on conflict(attendance_date,student_id) do update set status=excluded.status,remark=excluded.remark,updated_by=excluded.updated_by,updated_at=now();
  end loop;
  return true;
end;
$$;

revoke all on function public.get_class_attendance(text,text,date) from public;
revoke all on function public.save_class_attendance(text,text,date,jsonb) from public;
grant execute on function public.get_class_attendance(text,text,date) to anon,authenticated;
grant execute on function public.save_class_attendance(text,text,date,jsonb) to anon,authenticated;
notify pgrst, 'reload schema';
