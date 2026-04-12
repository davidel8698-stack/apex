# Workflow: Add Data Export

## Goal
Add data export capability to an existing application. Covers CSV/Excel/JSON export, large dataset handling, and async export for big files.

## Prerequisites
- Existing application with data to export (users, transactions, reports, analytics)
- Export formats determined (CSV, Excel/XLSX, JSON, or PDF)

## Phases

### Phase 1: Export Engine
- Install export libraries matching formats (csv-writer, exceljs, xlsx, or json2csv)
- Create export utility module with format-specific generators
- Implement data query with pagination/streaming (don't load entire dataset into memory)
- Add column mapping configuration (database fields → human-readable headers)
- Create export endpoint (`GET /api/export/:resource?format=csv&filters=...`)
- Verify: small dataset exports correctly in each format; column headers match spec

### Phase 2: Large Dataset & Async Export
- Implement streaming export for large datasets (>10K rows) — write chunks to response or file
- Add background job for very large exports (>100K rows) — generate file async, notify when ready
- Create temporary file storage for async exports (auto-delete after 24 hours)
- Add export progress tracking for async jobs
- Implement download endpoint for completed async exports
- Verify: large export doesn't crash or timeout; async export completes and notifies; download works; temp files cleaned up

## Skills Required
- Export library matching formats (csv, excel, json)
- Background job processing (for async exports)

## Security Invariants
- Export endpoint MUST require authentication and authorization
- Exported data MUST respect the user's access level (no data the user can't see in the UI)
- Export files MUST be encrypted at rest if containing PII
- Temporary export files MUST be auto-deleted after expiry
- Export operations MUST be audit logged (who exported what, when)
