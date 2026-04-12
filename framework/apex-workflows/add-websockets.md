# Workflow: Add WebSockets

## Goal
Add real-time communication via WebSockets to an existing application. Covers server setup, client integration, room/channel management, and reconnection handling.

## Prerequisites
- Existing web application with API server
- Real-time use case identified (chat, notifications, live updates, collaborative editing)
- WebSocket library selected (Socket.IO, ws, Phoenix Channels, or native WebSocket)

## Phases

### Phase 1: Server-Side WebSocket Setup
- Install WebSocket library matching project stack
- Create WebSocket server alongside existing HTTP server (shared port or separate)
- Implement connection lifecycle: connect, authenticate, disconnect, error handling
- Add room/channel abstraction for grouping connections (e.g., per-user, per-resource)
- Add connection heartbeat/ping-pong to detect stale connections
- Verify: WebSocket server accepts connections; authenticated clients join rooms; stale connections cleaned up

### Phase 2: Client Integration
- Add WebSocket client to frontend (matching library)
- Implement automatic reconnection with exponential backoff
- Add connection state indicator in UI (connected/disconnected/reconnecting)
- Implement message sending and receiving for primary use case
- Handle offline queue (buffer messages while disconnected, send on reconnect)
- Verify: client connects and reconnects; messages flow bidirectionally; UI reflects connection state

### Phase 3: Scaling & Reliability
- Add Redis adapter (or equivalent) for multi-server message broadcasting
- Implement rate limiting on incoming WebSocket messages
- Add structured logging for WebSocket events (connect, disconnect, message, error)
- Handle graceful shutdown (notify clients, drain connections)
- Load test concurrent connections at expected scale
- Verify: messages broadcast across multiple server instances; rate limiting works; graceful shutdown notifies clients

## Skills Required
- WebSocket library matching stack (socket-io, ws, phoenix-channels)
- Frontend framework skill
- Redis (if multi-server)

## Security Invariants
- WebSocket connections MUST be authenticated (token validation on connect)
- Room/channel access MUST be authorized (users can only join rooms they have permission for)
- Message payloads MUST be validated and sanitized (prevent XSS via WebSocket)
- Rate limiting MUST be enforced per connection
