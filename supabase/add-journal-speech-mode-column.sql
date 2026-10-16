-- Добавляет поле "Речевой режим" в дневник. Выполнить ОДИН РАЗ в
-- Supabase -> SQL Editor -> New query -> Run. Безопасно выполнять повторно.

alter table journal_entries add column if not exists speech_mode text;
