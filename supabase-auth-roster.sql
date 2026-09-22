-- 花名册账号与权限升级脚本
-- 先执行 supabase-schema.sql，再执行本文件。
-- Supabase Dashboard > Authentication > URL Configuration 中，
-- 请把 Site URL 设置为 https://llres.github.io，并加入
-- https://llres.github.io/class-tool.html 作为 Redirect URL。

create table if not exists public.class_accounts (
  user_id uuid primary key references auth.users(id) on delete cascade,
  student_id text not null unique references public.class_students(student_id) on update cascade,
  email text not null,
  role text not null default 'member' check (role in ('member','admin','super_admin')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.class_accounts enable row level security;
revoke all on public.class_accounts from anon, authenticated;

create or replace function public.claim_class_account(p_student_id text, p_email text)
returns boolean
language plpgsql security definer set search_path=public,auth as $$
begin
  if auth.uid() is null or lower(trim(p_email)) <> lower(coalesce((select email from auth.users where id=auth.uid()),'')) then
    return false;
  end if;
  if not exists (select 1 from public.class_students where student_id=trim(p_student_id)) then return false; end if;
  insert into public.class_accounts(user_id,student_id,email)
  values(auth.uid(),trim(p_student_id),lower(trim(p_email)))
  on conflict (user_id) do update set email=excluded.email,updated_at=now();
  return true;
exception when unique_violation then
  return false;
end;
$$;

create or replace function public.get_my_class_role()
returns table(student_id text,email text,role text)
language sql security definer set search_path=public as $$
  select student_id,email,role from public.class_accounts where user_id=auth.uid();
$$;

create or replace function public.get_class_roster_auth()
returns table(student_id text,name text,gender text,phone text,dorm text)
language sql security definer set search_path=public as $$
  select s.student_id,s.name,s.gender,s.phone,s.dorm
  from public.class_students s
  where exists (select 1 from public.class_accounts a where a.user_id=auth.uid());
$$;

create or replace function public.set_class_account_role(p_student_id text,p_role text)
returns boolean
language plpgsql security definer set search_path=public as $$
begin
  if not exists (select 1 from public.class_accounts where user_id=auth.uid() and role='super_admin') then return false; end if;
  if p_role not in ('member','admin','super_admin') then return false; end if;
  update public.class_accounts set role=p_role,updated_at=now() where student_id=p_student_id;
  return found;
end;
$$;

create or replace function public.list_class_accounts()
returns table(student_id text,email text,role text)
language sql security definer set search_path=public as $$
  select a.student_id,a.email,a.role
  from public.class_accounts a
  where exists (select 1 from public.class_accounts me where me.user_id=auth.uid() and me.role='super_admin')
  order by a.student_id;
$$;

create or replace function public.admin_upsert_student_auth(
  p_old_student_id text,p_student_id text,p_name text,p_gender text,p_phone text,p_dorm text
)
returns boolean language plpgsql security definer set search_path=public as $$
declare r text;
begin
  select role into r from public.class_accounts where user_id=auth.uid();
  if r not in ('admin','super_admin') then return false; end if;
  if p_old_student_id is not null and p_old_student_id<>'' and p_old_student_id<>p_student_id then
    update public.class_students set student_id=p_student_id,name=p_name,gender=p_gender,phone=coalesce(p_phone,''),dorm=coalesce(p_dorm,''),updated_at=now() where student_id=p_old_student_id;
  else
    insert into public.class_students(student_id,name,gender,phone,dorm)
    values(p_student_id,p_name,p_gender,coalesce(p_phone,''),coalesce(p_dorm,''))
    on conflict(student_id) do update set name=excluded.name,gender=excluded.gender,phone=excluded.phone,dorm=excluded.dorm,updated_at=now();
  end if;
  return found;
end;
$$;

create or replace function public.admin_delete_student_auth(p_student_id text)
returns boolean language plpgsql security definer set search_path=public as $$
declare r text;
begin
  select role into r from public.class_accounts where user_id=auth.uid();
  if r not in ('admin','super_admin') or p_student_id='26050008' then return false; end if;
  delete from public.class_students where student_id=p_student_id;
  return found;
end;
$$;

grant execute on function public.claim_class_account(text,text) to authenticated;
grant execute on function public.get_my_class_role() to authenticated;
grant execute on function public.get_class_roster_auth() to authenticated;
grant execute on function public.set_class_account_role(text,text) to authenticated;
grant execute on function public.list_class_accounts() to authenticated;
grant execute on function public.admin_upsert_student_auth(text,text,text,text,text,text) to authenticated;
grant execute on function public.admin_delete_student_auth(text) to authenticated;

-- 首个超级管理员需要先用邮箱注册并绑定学号，再执行：
-- update public.class_accounts set role='super_admin'
-- where student_id='26050008' and email='你的管理员邮箱';
notify pgrst, 'reload schema';
