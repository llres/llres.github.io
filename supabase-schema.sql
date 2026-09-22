create extension if not exists pgcrypto;

create table if not exists public.class_settings (id boolean primary key default true check (id), password_hash text not null);
create table if not exists public.class_students (student_id text primary key, name text not null, gender text not null, dorm text not null default '', phone text not null default '', remark text not null default '', updated_at timestamptz not null default now());

insert into public.class_settings (id,password_hash) values (true, crypt('请在执行前替换为你的管理密码', gen_salt('bf'))) on conflict (id) do nothing;

insert into public.class_students (student_id,name,gender) values
('1','李亦晨','男'),
('2','唐若尚','女'),
('3','胡文涛','男'),
('4','杨清奥','男'),
('5','张博雯','男'),
('6','李天奥','男'),
('7','刘尚博','男'),
('8','苏汉涛','男'),
('9','卢明建','男'),
('10','段心仪','女'),
('11','舒全桢','男'),
('12','宦棋缤','男'),
('13','王思源','男'),
('14','刘凯','男'),
('15','金思宜','男'),
('16','张嘉豪','男'),
('17','李植佳','女'),
('18','刘宇晨','男'),
('19','张汉东','男'),
('20','赵璟睿','男'),
('21','王禹皓','男'),
('22','秦子欢','女'),
('23','向文越','女'),
('24','张语俊','男'),
('25','黄晗菲','女'),
('26','汤诗源','男'),
('27','姜萌','女'),
('28','皮子萱','女'),
('29','冯语晨','女'),
('30','张军超','男'),
('31','王绍凡','男'),
('32','王永墙','男'),
('33','李青格','女'),
('34','杨笑童','女'),
('35','张静雪','女'),
('36','王靖倪','女'),
('37','刘靓盈','女'),
('38','郭凤霞','女'),
('39','涂奥琪','女'),
('40','任欣怡','女'),
('41','辛佳怡','女'),
('42','纪梦涵','女');

alter table public.class_settings enable row level security;
alter table public.class_students enable row level security;

create or replace function public.verify_class_access(p_student_id text,p_password text) returns boolean language sql security definer set search_path=public as $$ select exists(select 1 from class_students s,class_settings c where s.student_id=p_student_id and crypt(p_password,c.password_hash)=c.password_hash); $$;
create or replace function public.get_class_students(p_password text) returns table(student_id text,name text,gender text,dorm text,phone text,remark text,updated_at timestamptz) language sql security definer set search_path=public as $$ select s.student_id,s.name,s.gender,s.dorm,s.phone,s.remark,s.updated_at from class_students s,class_settings c where crypt(p_password,c.password_hash)=c.password_hash order by s.student_id::int; $$;
create or replace function public.update_student_info(p_password text,p_student_id text,p_dorm text,p_phone text,p_remark text) returns boolean language plpgsql security definer set search_path=public as $$ begin if not exists(select 1 from class_settings where crypt(p_password,password_hash)=password_hash) then return false; end if; update class_students set dorm=coalesce(p_dorm,''),phone=coalesce(p_phone,''),remark=coalesce(p_remark,''),updated_at=now() where student_id=p_student_id; return found; end; $$;
revoke all on table public.class_settings from anon,authenticated;
revoke all on table public.class_students from anon,authenticated;
grant execute on function public.verify_class_access(text,text) to anon,authenticated;
grant execute on function public.get_class_students(text) to anon,authenticated;
grant execute on function public.update_student_info(text,text,text,text,text) to anon,authenticated;
