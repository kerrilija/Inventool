CREATE TABLE app_config (
  id bigserial PRIMARY KEY,
  key TEXT UNIQUE NOT NULL,
  value TEXT NOT NULL
);