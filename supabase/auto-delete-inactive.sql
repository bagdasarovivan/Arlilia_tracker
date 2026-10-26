-- Автоудаление данных тех, кто не заходил в приложение больше 30 дней.
-- Выполнить ОДИН РАЗ в Supabase -> SQL Editor -> New query -> Run.
-- Удаляются ВСЕ записи человека (подходы, дневник, настройки) и сам аккаунт —
-- это НЕОБРАТИМО. Читайте шаги по порядку.

-- ШАГ 1. Приложение будет отмечать дату последнего захода.
alter table app_settings add column if not exists last_seen_at timestamptz;

-- ШАГ 2. Вставьте СВОЙ email (и email логопеда/любых аккаунтов, которые
-- нельзя удалять) в список ниже. Эти аккаунты функция никогда не тронет.
create table if not exists protected_accounts (email text primary key);
insert into protected_accounts (email) values
  ('bagdasarivan@gmail.com')
on conflict do nothing;

-- ШАГ 3. Функция очистки. «Последний заход» = самая поздняя из дат:
-- last_seen_at, последний подход, последняя запись дневника, последний вход,
-- создание аккаунта. Так никто не пострадает из-за того, что ещё не успел
-- открыть обновлённое приложение.
create or replace function delete_inactive_users(days int default 30, dry_run boolean default true)
returns table(user_email text, last_activity timestamptz)
language plpgsql security definer set search_path = public, auth as $$
declare r record;
begin
  for r in
    select u.id, u.email,
      greatest(
        u.created_at,
        coalesce(u.last_sign_in_at, u.created_at),
        coalesce((select max(last_seen_at) from app_settings s where s.user_id = u.id), u.created_at),
        coalesce((select max(created_at) from attempts a where a.user_id = u.id), u.created_at),
        coalesce((select max(created_at) from journal_entries j where j.user_id = u.id), u.created_at)
      ) as last_act
    from auth.users u
    where u.email not in (select email from protected_accounts)
  loop
    if r.last_act < now() - make_interval(days => days) then
      user_email := r.email; last_activity := r.last_act; return next;
      if not dry_run then
        delete from attempts where user_id = r.id;
        delete from journal_entries where user_id = r.id;
        delete from app_settings where user_id = r.id;
        delete from exercise_log where user_id = r.id;
        delete from auth.users where id = r.id;
      end if;
    end if;
  end loop;
end $$;

-- ШАГ 4. ПРОБНЫЙ запуск — только покажет, кого бы удалили, ничего не удаляет:
select * from delete_inactive_users(30, true);

-- ШАГ 5. Когда убедитесь, что список верный, включите ежедневный запуск.
-- (Сначала включите расширение: Database -> Extensions -> pg_cron.)
-- Раскомментируйте и выполните:
-- select cron.schedule('delete-inactive-users', '0 3 * * *',
--   $$ select delete_inactive_users(30, false) $$);

-- Отключить автоудаление:
-- select cron.unschedule('delete-inactive-users');
