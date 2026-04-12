# Workflow: Add File Uploads

## Goal
Add file upload capability to an existing application. Covers storage configuration, upload API, file validation, and serving/downloading files.

## Prerequisites
- Existing application with API endpoints
- Storage backend selected (local filesystem, S3, GCS, Azure Blob, or Cloudflare R2)
- Maximum file size and allowed types determined

## Phases

### Phase 1: Storage & Upload API
- Install storage client library (AWS SDK, GCS SDK, or multer/busboy for local)
- Configure storage backend connection (bucket, credentials, region)
- Create upload endpoint with multipart form handling
- Implement file validation: size limit, allowed MIME types, filename sanitization
- Generate unique storage keys (UUID-based, not user-provided filenames)
- Store file metadata in database (original name, size, type, storage key, uploaded_by, created_at)
- Verify: file uploads succeed; validation rejects oversized and disallowed files; metadata stored

### Phase 2: Serving & Management
- Create download/serve endpoint with proper Content-Type and Content-Disposition headers
- Implement pre-signed URLs for direct-to-storage downloads (if using cloud storage)
- Add file deletion endpoint with authorization check
- Create image thumbnail generation (if applicable — use sharp, Pillow, or equivalent)
- Add file listing endpoint with pagination
- Verify: files downloadable; unauthorized users cannot access others' files; thumbnails generated

### Phase 3: Resilience & Optimization
- Add upload progress tracking (chunked upload or progress events)
- Implement virus/malware scanning on upload (ClamAV or cloud-native scanner)
- Configure storage lifecycle rules (auto-delete temporary files after N days)
- Add CDN integration for frequently accessed files (if applicable)
- Verify: progress tracking works; malicious files rejected; lifecycle rules applied

## Skills Required
- Storage backend skill (s3, gcs, azure-blob)
- Database skill matching project stack

## Security Invariants
- Uploaded files MUST be validated by MIME type and magic bytes (not just extension)
- Storage keys MUST be UUID-based (never use user-provided filenames as storage paths)
- Files MUST NOT be served from the application's web root (prevent path traversal)
- Download endpoints MUST check authorization
- Executable files MUST be rejected (.exe, .sh, .bat, .cmd, .php, .jsp)
