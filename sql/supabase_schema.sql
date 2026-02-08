-- ============================================
-- FACELESS YOUTUBE AUTOMATION - SUPABASE SCHEMA
-- ============================================
-- Version: 1.2.0
-- Last Updated: 2026-02-08
-- ============================================

-- --------------------------------------------
-- 1. STORAGE BUCKET: audio
-- --------------------------------------------
-- Purpose: Store generated TTS audio files
-- Visibility: Public (audio files need to be accessible by Creatomate)
-- Size Limit: 10MB per file
-- MIME Types: audio/mpeg, audio/mp3, audio/wav
-- --------------------------------------------

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'audio',
  'audio',
  true,
  10485760,  -- 10MB in bytes
  ARRAY['audio/mpeg', 'audio/mp3', 'audio/wav']
)
ON CONFLICT (id) DO NOTHING;

-- --------------------------------------------
-- 2. TABLE: workflow_logs
-- --------------------------------------------
-- Purpose: Log all workflow executions, errors, and events
-- Used by: Error Handler (Node 22) in n8n workflow
-- Retention: No automatic cleanup (add CRON job if needed)
-- --------------------------------------------

CREATE TABLE IF NOT EXISTS workflow_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workflow_name TEXT NOT NULL,
  execution_id TEXT NOT NULL,
  event TEXT NOT NULL,
  error_message TEXT,
  error_node TEXT,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- --------------------------------------------
-- 3. INDEXES
-- --------------------------------------------
-- Purpose: Optimize query performance for common lookups
-- --------------------------------------------

-- Index for filtering by execution_id (fast lookup of all logs for one execution)
CREATE INDEX IF NOT EXISTS idx_workflow_logs_execution 
  ON workflow_logs(execution_id);

-- Index for time-based queries (get recent logs)
CREATE INDEX IF NOT EXISTS idx_workflow_logs_timestamp 
  ON workflow_logs(timestamp DESC);

-- Index for filtering by workflow_name (useful when running multiple workflows)
CREATE INDEX IF NOT EXISTS idx_workflow_logs_workflow_name 
  ON workflow_logs(workflow_name);

-- --------------------------------------------
-- 4. COMMENTS (Documentation)
-- --------------------------------------------

COMMENT ON TABLE workflow_logs IS 'Logs for n8n workflow executions, errors, and events';
COMMENT ON COLUMN workflow_logs.execution_id IS 'n8n execution ID ($execution.id)';
COMMENT ON COLUMN workflow_logs.event IS 'Event type: workflow_error, workflow_success, etc.';
COMMENT ON COLUMN workflow_logs.error_node IS 'Name of the node where error occurred';

-- --------------------------------------------
-- 5. ROW LEVEL SECURITY (RLS) - Optional
-- --------------------------------------------
-- If you want to restrict access to logs, enable RLS:
-- ALTER TABLE workflow_logs ENABLE ROW LEVEL SECURITY;
-- 
-- Example policy (allow service role full access):
-- CREATE POLICY "Service role can manage all logs"
--   ON workflow_logs
--   FOR ALL
--   TO service_role
--   USING (true)
--   WITH CHECK (true);

-- --------------------------------------------
-- 6. SAMPLE QUERIES
-- --------------------------------------------

-- Get all logs for a specific execution:
-- SELECT * FROM workflow_logs 
-- WHERE execution_id = 'abc-123-def' 
-- ORDER BY timestamp;

-- Get recent errors (last 24 hours):
-- SELECT * FROM workflow_logs 
-- WHERE event = 'workflow_error' 
--   AND timestamp > NOW() - INTERVAL '24 hours'
-- ORDER BY timestamp DESC;

-- Count errors per node:
-- SELECT error_node, COUNT(*) as error_count
-- FROM workflow_logs
-- WHERE event = 'workflow_error'
-- GROUP BY error_node
-- ORDER BY error_count DESC;

-- ============================================
-- SETUP COMPLETE
-- ============================================
-- Next Steps:
-- 1. Configure n8n environment variables
-- 2. Import workflow from n8n/workflow.json
-- 3. Set up credentials in n8n UI
-- 4. Test with sample request
-- ============================================
