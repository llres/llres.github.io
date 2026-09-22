-- Update the existing class roster to the official student IDs from the 2026 registration list.
-- Run this once in Supabase SQL Editor after the base schema has been created.

update public.class_students set student_id = '26050001' where student_id = '1';
update public.class_students set student_id = '26050002' where student_id = '2';
update public.class_students set student_id = '26050003' where student_id = '3';
update public.class_students set student_id = '26050004' where student_id = '4';
update public.class_students set student_id = '26050005' where student_id = '5';
update public.class_students set student_id = '26050006' where student_id = '6';
update public.class_students set student_id = '26050007' where student_id = '7';
update public.class_students set student_id = '26050008' where student_id = '8';
update public.class_students set student_id = '26050009' where student_id = '9';
update public.class_students set student_id = '26050010' where student_id = '10';
update public.class_students set student_id = '26050011' where student_id = '11';
update public.class_students set student_id = '26050012' where student_id = '12';
update public.class_students set student_id = '26050013' where student_id = '13';
update public.class_students set student_id = '26050014' where student_id = '14';
update public.class_students set student_id = '26050015' where student_id = '15';
update public.class_students set student_id = '26050016' where student_id = '16';
update public.class_students set student_id = '26050017' where student_id = '17';
update public.class_students set student_id = '26050018' where student_id = '18';
update public.class_students set student_id = '26050019' where student_id = '19';
update public.class_students set student_id = '26050020' where student_id = '20';
update public.class_students set student_id = '26050021' where student_id = '21';
update public.class_students set student_id = '26050022' where student_id = '22';
update public.class_students set student_id = '26050023' where student_id = '23';
update public.class_students set student_id = '26050024' where student_id = '24';
update public.class_students set student_id = '26050025' where student_id = '25';
update public.class_students set student_id = '26050026' where student_id = '26';
update public.class_students set student_id = '26050027' where student_id = '27';
update public.class_students set student_id = '26050028' where student_id = '28';
update public.class_students set student_id = '26050029' where student_id = '29';
update public.class_students set student_id = '26050030' where student_id = '30';
update public.class_students set student_id = '26050031' where student_id = '31';
update public.class_students set student_id = '26050032' where student_id = '32';
update public.class_students set student_id = '26050033' where student_id = '33';
update public.class_students set student_id = '26050034' where student_id = '34';
update public.class_students set student_id = '26050035' where student_id = '35';
update public.class_students set student_id = '26050036' where student_id = '36';
update public.class_students set student_id = '26050037' where student_id = '37';
update public.class_students set student_id = '26050038' where student_id = '38';
update public.class_students set student_id = '26050039' where student_id = '39';
update public.class_students set student_id = '26050040' where student_id = '40';
update public.class_students set student_id = '26050041' where student_id = '41';
update public.class_students set student_id = '26050042' where student_id = '42';

-- Verify the migration:
select student_id,name,gender from public.class_students order by student_id;
