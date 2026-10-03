-- Добавляет текстовое поле к полю "Сон" в дневнике — теперь можно
-- писать не только число часов, но и словами (например "спал плохо,
-- просыпался несколько раз"). Выполнить ОДИН РАЗ в Supabase ->
-- SQL Editor -> New query -> Run. Безопасно выполнять повторно.

alter table journal_entries add column if not exists sleep_note text;
