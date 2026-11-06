CREATE TABLE IF NOT EXISTS logs (
  id bigserial PRIMARY KEY,
  created_at timestamptz NOT NULL DEFAULT now(),
  version text, build text, platform text, user_agent text,
  result text, wave int, duration_s real,
  ip_hash text, content text NOT NULL
);
CREATE INDEX IF NOT EXISTS logs_created_at_idx ON logs (created_at);
CREATE INDEX IF NOT EXISTS logs_ip_hash_idx ON logs (ip_hash);
