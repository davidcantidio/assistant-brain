CREATE TABLE IF NOT EXISTS event_ledger (
  sequence_id BIGSERIAL PRIMARY KEY,
  event_id TEXT NOT NULL UNIQUE,
  stream_id TEXT NOT NULL,
  idempotency_key TEXT NOT NULL UNIQUE,
  replay_key TEXT NOT NULL,
  command_id TEXT NOT NULL,
  author TEXT NOT NULL,
  evidence_ref TEXT NOT NULL,
  channel TEXT NOT NULL,
  action TEXT NOT NULL,
  occurred_at TIMESTAMPTZ NOT NULL,
  payload_digest TEXT NOT NULL,
  payload_jsonb JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS event_ledger_stream_idx
  ON event_ledger(stream_id, sequence_id);

CREATE OR REPLACE FUNCTION deny_event_ledger_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  RAISE EXCEPTION 'event_ledger is append-only';
END;
$$;

DROP TRIGGER IF EXISTS event_ledger_no_update_delete ON event_ledger;
CREATE TRIGGER event_ledger_no_update_delete
BEFORE UPDATE OR DELETE ON event_ledger
FOR EACH ROW
EXECUTE FUNCTION deny_event_ledger_mutation();
