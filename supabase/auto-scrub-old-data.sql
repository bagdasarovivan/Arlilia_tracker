-- Ограниченное хранение данных. Выполнить ОДИН РАЗ в Supabase ->
-- SQL Editor -> New query -> Run. Читайте шаги по порядку.
--
--   * Дневник: через 3 дня текст записи удаляется, остаётся только факт,
--     что в этот день дневник был заполнен.
--   * Подходы: через 7 дней подробности удаляются, остаётся только сам
--     подход (дата и время), то есть количество подходов.
--
-- Удаление НЕОБРАТИМО.

-- ШАГ 1. Отметка «подробности удалены» (приложение по ней показывает пометку).
alter table journal_entries add column if not exists scrubbed_at timestamptz;
alter table attempts add column if not exists scrubbed_at timestamptz;

-- ШАГ 2. Функция очистки. dry_run = true — ничего не меняет, только считает.
create or replace function scrub_old_data(journal_days int default 3, attempt_days int default 7, dry_run boolean default true)
returns table(what text, rows_affected bigint)
language plpgsql security definer set search_path = public as $$
begin
  if dry_run then
    return query select 'дневник: будет очищено'::text,
      (select count(*) from journal_entries where scrubbed_at is null and entry_date <= current_date - journal_days);
    return query select 'подходы: будет очищено'::text,
      (select count(*) from attempts where scrubbed_at is null and created_at < now() - make_interval(days => attempt_days));
    return;
  end if;

  update journal_entries set
    mood = null, glad = null, worry = null, speech_mode = null, daily_routine = null,
    sleep_hours = null, sleep_note = null, difficulties = null, questions = null,
    reflections = null, tricks = null, praise = null, intentions = null,
    scrubbed_at = now()
  where scrubbed_at is null and entry_date <= current_date - journal_days;

  update attempts set
    title = null, mindset_before = null, reaction_after = null,
    ritual = null, ritual_note = null,
    voice = null, voice_note = null, hand = null, hand_note = null,
    anxiety = null, anxiety_note = null, purpose = null,
    scrubbed_at = now()
  where scrubbed_at is null and created_at < now() - make_interval(days => attempt_days);
end $$;

-- ШАГ 3. ПРОБА — покажет, сколько записей будет очищено, ничего не меняя:
select * from scrub_old_data(3, 7, true);

-- ШАГ 4. Включите расширение pg_cron (Database -> Extensions -> pg_cron),
-- потом раскомментируйте и выполните — очистка будет идти каждую ночь:
-- select cron.schedule('scrub-old-data', '30 3 * * *',
--   $$ select scrub_old_data(3, 7, false) $$);

-- Отключить:
-- select cron.unschedule('scrub-old-data');
