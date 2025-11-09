# C Demo (examples/demo)

This example builds a minimal HTTP server using the webserver library and registers a few routes.

Routes
- GET /        → “Hello, World”
- GET /health  → “OK”
- GET /metrics → Text metrics (accepted, enqueued, dequeued, drops, bytes_sent, response-class counters, queue stats, threads)

Build
1) Build the library and demo:
   make

2) Run the demo:
   ./webserver-demo -p 8080

Useful flags
- -p, --port PORT              TCP port (default 8080)
- -t, --threads N              Worker thread count (default: cores, min 2)
- -q, --queue CAP              Work queue capacity (default 1024)
- -b, --backlog N              listen backlog (default SOMAXCONN)
- --keepalive 0|1              Enable/disable HTTP keep-alive
- --ka-timeout MS              Keep-alive idle timeout in milliseconds (default 15000)
- --ka-max-req N               Max requests per connection (default 100)
- --queue-policy POLICY        Backpressure strategy: block|drop-new|drop-oldest

Examples
- Basic:
  ./webserver-demo -p 8080

- Enable keep-alive, custom queue and backlog:
  ./webserver-demo -p 8081 -t 4 -q 64 -b 64 --keepalive 1 --ka-timeout 5000 --ka-max-req 5

- Change queue policy to drop-new:
  ./webserver-demo --queue-policy drop-new

Test with curl
- curl -s -D - http://127.0.0.1:8080/
- curl -s -D - http://127.0.0.1:8080/health
- curl -s -D - http://127.0.0.1:8080/metrics

Shutdown
- Press Ctrl+C in the terminal; the demo installs a SIGINT handler to request a graceful shutdown.
