-- Безопасная миграция duration_minutes для существующих мероприятий.
ALTER TABLE events ADD COLUMN IF NOT EXISTS duration_minutes integer DEFAULT 60;
UPDATE events SET duration_minutes = 60 WHERE duration_minutes IS NULL;
ALTER TABLE events ALTER COLUMN duration_minutes SET DEFAULT 60;
