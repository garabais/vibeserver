# C Webserver Template

Notice: This repository was vibe coded using Cline and GPT‑5 to test current AI code generation capabilities.

Overview
- POSIX C HTTP server library with acceptor + worker thread pool
- HTTP/1.x request parsing (start line + headers, up to WS_MAX_HEADERS=255)
- Keep‑alive with Connection semantics:
  - HTTP/1.1: keep‑alive by default unless Connection: close
  - HTTP/1.0: keep‑alive only if Connection: keep‑alive
- Configurable:
  - Thread count, queue capacity, listen backlog
  - Keep‑alive enable/timeout/max‑requests
  - Queue policy: block, drop‑new, drop‑oldest
- Logging:
  - Pluggable logger callback with levels; default stderr logger with optional format
- Metrics:
  - bytes_sent; responses 2xx/3xx/4xx/5xx
  - accepted/enqueued/dequeued
  - dropped_new/dropped_oldest
  - queue length + peak
- Public/Private header split; Doxygen public/internal docs

Public API highlights (see lib/webserver/include/webserver.h)
- Request and handlers
  - ws_request: fd, method, path, http_major/minor, keep_alive, headers view, optional body view, server pointer
  - ws_handler_fn(const ws_request* req, void* user)
- Construction
  - ws_server_new_with_opts(const ws_server_opts* opts)
  - ws_server_new / ws_server_new_ex
- Routing
  - ws_server_add_route(ws_server* s, const char* method, const char* path, ws_handler_fn cb, void* user)
- Run/Shutdown
  - ws_server_run(ws_server* s)
  - ws_server_request_shutdown(ws_server* s)
- Response helper + metrics
  - ws_send_response(const ws_request* req, ...)
  - ws_server_get_metrics(ws_server* s, ws_metrics* out)

Build
- Build library and C demo:
  - make

C demo (examples/demo)
- Run:
  - ./webserver-demo -p 8080
- Try it:
  - curl -s -D - http://127.0.0.1:8080/
  - curl -s -D - http://127.0.0.1:8080/health
  - curl -s -D - http://127.0.0.1:8080/metrics
- Useful flags:
  - -p, --port PORT
  - -t, --threads N
  - -q, --queue CAP
  - -b, --backlog N
  - --keepalive 0|1
  - --ka-timeout MS
  - --ka-max-req N
  - --queue-policy block|drop-new|drop-oldest
- Graceful shutdown: Ctrl+C (SIGINT)

Zig demo (examples/zig-demo)
- Prerequisite: build the C library first
  - make
- Build & run with Zig:
  - cd examples/zig-demo
  - zig build run
- Notes:
  - build.zig links against ../../build/libwebserver.a and includes ../../lib/webserver/include
  - Handler is implemented in Zig and calls ws_send_response via @cImport

Generate docs
- Public API docs:
  - make docs-public
  - Output: docs/public/html/index.html
- Internal docs:
  - make docs-internal
  - Output: docs/internal/html/index.html
- Both:
  - make docs

Repository layout (selected)
- lib/webserver/include/     Public headers (webserver.h, http.h)
- lib/webserver/src/         Library sources (server.c, router.c, http.c, util.c)
- lib/webserver/src/if/      Internal/private headers (router0.h, server0.h, util0.h)
- examples/demo/             C demo (main.c + README.md)
- examples/zig-demo/         Zig demo (build.zig, src/main.zig)
- docs/public/, docs/internal/  Doxygen output (after make docs)
- next_steps.md              Completed + pending recommendations

Next steps
See next_steps.md for a checklist of completed work and future enhancements (body streaming, header utilities, chunked transfer, per‑route metrics, evented accept, more examples, CI, etc.).
