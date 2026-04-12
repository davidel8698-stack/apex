# Workflow: Add Search

## Goal
Add full-text search capability to an existing application. Covers search engine integration, indexing strategy, search API, and relevance tuning.

## Prerequisites
- Existing application with content to search (products, articles, users, etc.)
- Search backend selected (Elasticsearch, Meilisearch, Algolia, PostgreSQL full-text, or Typesense)
- Data model identified for searchable entities

## Phases

### Phase 1: Search Engine Setup
- Install search client library matching project stack
- Configure search engine connection (URL, API key, index name)
- Define search index schema: searchable fields, filterable fields, sortable fields
- Create indexing pipeline: bulk import existing data into search index
- Add search engine health check to application health endpoint
- Verify: search engine accessible; existing data indexed; health check reports status

### Phase 2: Search API & Sync
- Create search API endpoint (`GET /api/search?q=...&filters=...&page=...`)
- Implement query parsing: search terms, filters, pagination, sorting
- Add real-time index sync: on create/update/delete → update search index
- Handle search engine downtime gracefully (queue updates, fallback to DB query)
- Verify: search returns relevant results; new/updated/deleted records reflected in search

### Phase 3: Relevance & UX
- Configure field boosting (title matches rank higher than body matches)
- Add typo tolerance and synonym support
- Implement search suggestions / autocomplete endpoint
- Add search analytics (what users search for, zero-result queries)
- Optimize search latency (< 100ms p95 target)
- Verify: search results are relevant; typos handled; autocomplete works; latency within target

## Skills Required
- Search engine skill (elasticsearch, meilisearch, algolia)
- Database skill matching project stack

## Security Invariants
- Search index MUST NOT contain sensitive fields (passwords, tokens, internal IDs not meant for users)
- Search API MUST respect access control (users can only search content they have permission to see)
- Search engine admin API MUST NOT be publicly accessible
- Query input MUST be sanitized to prevent injection attacks
