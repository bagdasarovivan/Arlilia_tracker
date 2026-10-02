-- Многопользовательский доступ для Arlilia tracker.
-- Выполнить ОДИН РАЗ целиком в Supabase -> SQL Editor -> New query -> Run.
--
-- Вместо того чтобы вписывать UID вручную (это и вызвало прошлую ошибку
-- "is not present in table users" — UID разошёлся с реальным), запрос сам
-- находит ваш UID по email прямо в момент выполнения — так надёжнее.
-- Если захотите назначить старые записи на ДРУГОЙ аккаунт — просто замените
-- email ниже на нужный (он используется в 3 местах, в блоке №2).

-- 1) Добавляем user_id на все три таблицы
alter table attempts add column if not exists user_id uuid references auth.users(id);
alter table journal_entries add column if not exists user_id uuid references auth.users(id);
alter table app_settings add column if not exists user_id uuid references auth.users(id);

-- 2) Переносим уже существующие (старые, записанные до этого) строки на аккаунт с этим email
update attempts set user_id = (select id from auth.users where email = 'bagdasarivan@gmail.com') where user_id is null;
update journal_entries set user_id = (select id from auth.users where email = 'bagdasarivan@gmail.com') where user_id is null;
update app_settings set user_id = (select id from auth.users where email = 'bagdasarivan@gmail.com') where user_id is null;

-- 3) app_settings — одна строка на пользователя (ключ по user_id вместо id)
alter table app_settings drop constraint if exists app_settings_pkey;
alter table app_settings drop column if exists id;
alter table app_settings add primary key (user_id);

-- 4) journal_entries — одна запись на дату НА ПОЛЬЗОВАТЕЛЯ (а не одна на дату вообще)
alter table journal_entries drop constraint if exists journal_entries_entry_date_key;
alter table journal_entries drop constraint if exists journal_entries_entry_date_user_key;
alter table journal_entries add constraint journal_entries_entry_date_user_key unique (entry_date, user_id);

-- 5) Включаем RLS — каждый видит и может писать только свои строки
alter table attempts enable row level security;
alter table journal_entries enable row level security;
alter table app_settings enable row level security;

drop policy if exists "own rows" on attempts;
create policy "own rows" on attempts for all using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "own rows" on journal_entries;
create policy "own rows" on journal_entries for all using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "own rows" on app_settings;
create policy "own rows" on app_settings for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- 6) Проверка: если после запуска строк "0 rows" и всё прошло без ошибок —
-- выполните это отдельно, чтобы убедиться, что ни одной "осиротевшей" строки
-- без user_id не осталось (иначе она будет не видна под RLS никому):
-- select 'attempts' as t, count(*) from attempts where user_id is null
-- union all select 'journal_entries', count(*) from journal_entries where user_id is null
-- union all select 'app_settings', count(*) from app_settings where user_id is null;
