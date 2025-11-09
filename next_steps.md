# Project Next Steps and Recommendations

This document aggregates recommendations and future enhancements discussed during development. Items marked as completed have been implemented in the current codebase.

## Completed

- [x] Graceful shutdown (SIGINT handler)
  - ws_server_request_shutdown invoked from demo SIGINT handler; accept loop unblocks; workers wake via condvars.
- [x] Keep‑alive support with Connection semantics
  - HTTP/1.1: keep-alive by default unless `Connection: close`
  - HTTP/1.0: keep-alive only if `Connection: keep-alive`
  - Gated by `enable_keepalive` with idle timeout and max-requests.
- [x] Header parsing (request line + headers)
  - `http_parse_request` parses start line and headers up to CRLF CRLF with a cap of `WS_MAX_HEADERS` (255).
- [x] Metrics
  - `bytes_sent`, `responses_2xx/3xx/4xx/5xx`, `accepted/enqueued/dequeued`, `dropped_new/dropped_oldest`, queue peak and current length.
  - `/metrics` endpoint in demo.
- [x] Logging
  - Pluggable `ws_log_fn` with levels; default stderr logger with optional `{level}` / `{msg}` formatting via `log_format`.
- [x] Configuration knobs
  - Thread count, queue capacity, listen backlog, keep‑alive (enable, timeout, max requests), queue policy.
- [x] Queue backpressure policy
  - `WS_QUEUE_BLOCK`, `WS_QUEUE_DROP_NEW`, `WS_QUEUE_DROP_OLDEST` with drop counters.
- [x] Demo CLI flags and new handler API
  - Demo supports configuration flags and uses `ws_handler_fn(const ws_request*, void*)`.
- [x] Public API modernization
  - `ws_request`, `ws_handler_fn`, `ws_server_new_with_opts`, `ws_send_response`, expanded `ws_metrics`.
- [x] Doxygen documentation and cleanup
  - Built for public/internal; resolved duplication warnings; added missing docs and group declarations.

## Pending / Future Enhancements

- [ ] Request body reading / streaming
  - Read and expose request body when `Content-Length` is present.
  - Add size caps and optional streaming interface.
- [ ] Header utilities
  - Normalization and case‑insensitive lookup helpers for headers.
- [ ] HTTP features expansion
  - Chunked transfer decoding for requests.
  - Keep‑alive header negotiation and connection reuse improvements.
- [ ] Per‑request / per‑route metrics
  - Track per‑route request counts, response classes, bytes sent.
  - Optional latency histograms/timers.
- [ ] Evented/non‑blocking accept and advanced shutdown
  - Non‑blocking listen socket; eventfd/pipe for wakeup; configurable signals for graceful/forceful shutdown.
- [ ] Additional examples and integrations
  - More C examples (static files, JSON echo), integration with other languages (Rust/C++/Python FFI).
  - Benchmarks with wrk/ab and example scripts.
- [ ] CI for builds and docs
  - Continuous integration to build the library, examples, and Doxygen docs on pushes/PRs.
- [ ] Security hardening
  - Request size limits, header/body limits, conservative defaults for production.
- [ ] Logging improvements
  - Structured logging (JSON), multiple sinks, log rotation hooks.

## Notes

- Canonical API documentation lives in public headers to avoid duplication in implementation files.
- Internal helper functions include concise Doxygen comments where helpful; larger API explanations remain in headers.
