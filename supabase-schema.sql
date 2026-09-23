create extension if not exists pgcrypto;

create table if not exists public.class_settings (id boolean primary key default true check (id), password_hash text not null);
alter table public.class_settings add column if not exists admin_password_hash text;
create table if not exists public.class_students (student_id text primary key, name text not null, gender text not null, dorm text not null default '', phone text not null default '', remark text not null default '', updated_at timestamptz not null default now());

insert into public.class_settings (id,password_hash) values (true, extensions.crypt('请在执行前替换为你的管理密码', extensions.gen_salt('bf'))) on conflict (id) do nothing;
update public.class_settings set password_hash=extensions.crypt('dk2601', extensions.gen_salt('bf')),admin_password_hash=extensions.crypt('gl2601', extensions.gen_salt('bf')) where id=true;

insert into public.class_students (student_id,name,gender) values
('26050001','李亦晨','男'),
('26050002','唐若尚','女'),
('26050003','胡文涛','男'),
('26050004','杨清奥','男'),
('26050005','张博雯','男'),
('26050006','李天奥','男'),
('26050007','刘尚博','男'),
('26050008','苏汉涛','男'),
('26050009','卢明建','男'),
('26050010','段心仪','女'),
('26050011','舒全桢','男'),
('26050012','宦棋缤','男'),
('26050013','王思源','男'),
('26050014','刘凯','男'),
('26050015','金思宜','男'),
('26050016','张嘉豪','男'),
('26050017','李植佳','女'),
('26050018','刘宇晨','男'),
('26050019','张汉东','男'),
('26050020','赵璟睿','男'),
('26050021','王禹皓','男'),
('26050022','秦子欢','女'),
('26050023','向文越','女'),
('26050024','张语俊','男'),
('26050025','黄晗菲','女'),
('26050026','汤诗源','男'),
('26050027','姜萌','女'),
('26050028','皮子萱','女'),
('26050029','冯语晨','女'),
('26050030','张军超','男'),
('26050031','王绍凡','男'),
('26050032','王永墙','男'),
('26050033','李青格','女'),
('26050034','杨笑童','女'),
('26050035','张静雪','女'),
('26050036','王靖倪','女'),
('26050037','刘靓盈','女'),
('26050038','郭凤霞','女'),
('26050039','涂奥琪','女'),
('26050040','任欣怡','女'),
('26050041','辛佳怡','女'),
('26050042','纪梦涵','女');

alter table public.class_settings enable row level security;
alter table public.class_students enable row level security;

create or replace function public.verify_class_access(p_student_id text,p_password text) returns boolean language sql security definer set search_path=public as $$ select exists(select 1 from class_students s,class_settings c where s.student_id=p_student_id and extensions.crypt(p_password,c.password_hash)=c.password_hash); $$;
create or replace function public.get_class_students(p_password text) returns table(student_id text,name text,gender text,dorm text,phone text,remark text,updated_at timestamptz) language sql security definer set search_path=public as $$ select s.student_id,s.name,s.gender,s.dorm,s.phone,s.remark,s.updated_at from class_students s,class_settings c where extensions.crypt(p_password,c.password_hash)=c.password_hash order by s.student_id::int; $$;
create or replace function public.update_student_info(p_password text,p_student_id text,p_dorm text,p_phone text,p_remark text) returns boolean language plpgsql security definer set search_path=public as $$ begin if not exists(select 1 from class_settings where extensions.crypt(p_password,password_hash)=password_hash) then return false; end if; update class_students set dorm=coalesce(p_dorm,''),phone=coalesce(p_phone,''),remark=coalesce(p_remark,''),updated_at=now() where student_id=p_student_id; return found; end; $$;
revoke all on table public.class_settings from anon,authenticated;
revoke all on table public.class_students from anon,authenticated;
grant execute on function public.verify_class_access(text,text) to anon,authenticated;
grant execute on function public.get_class_students(text) to anon,authenticated;
grant execute on function public.update_student_info(text,text,text,text,text) to anon,authenticated;



