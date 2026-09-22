-- Set the shared class password after the schema has been created.
update public.class_settings
set password_hash = extensions.crypt('dk2601', extensions.gen_salt('bf'))
where id = true;
