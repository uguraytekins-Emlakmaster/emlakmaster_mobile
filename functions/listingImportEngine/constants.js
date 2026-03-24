const COL_LISTING_IMPORT_TASKS = "listing_import_tasks";
const COL_SYNC_LOGS = "integration_sync_logs";

/** @typedef {'url'|'file'|'extension'} ImportSourceType */
/** @typedef {'queued'|'processing'|'pending_approval'|'completed'|'failed'|'partial'} ImportTaskStatus */
/** @typedef {'skip_duplicates'|'update_duplicates'|'create_new'} ImportDuplicateMode */

const TASK_STATUSES = Object.freeze({
  queued: "queued",
  processing: "processing",
  pending_approval: "pending_approval",
  completed: "completed",
  failed: "failed",
  partial: "partial",
});

const SOURCE_TYPES = Object.freeze({
  url: "url",
  file: "file",
  extension: "extension",
});

module.exports = {
  COL_LISTING_IMPORT_TASKS,
  COL_SYNC_LOGS,
  TASK_STATUSES,
  SOURCE_TYPES,
};
