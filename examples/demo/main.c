/**
 * @file demo.c
 * @brief Demo application linking the webserver library and registering routes.
 */

#include "webserver.h"
#include "http.h"

#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <stdlib.h>
#include <signal.h>

/**
 * @brief Parse a TCP port (uint16) from a decimal string.
 * @param[in]  s         Null-terminated string.
 * @param[out] out_port  Output value on success.
 * @retval 0 on success
 * @retval -1 on error
 */
static int parse_port(const char *s, unsigned short *out_port) {
  if (!s || !*s) return -1;
  char *end = NULL;
  errno = 0;
  unsigned long v = strtoul(s, &end, 10);
  if (errno != 0 || end == s || *end != '\0' || v > 65535UL) return -1;
  *out_port = (unsigned short)v;
  return 0;
}

/* Global server pointer for SIGINT handler */
static ws_server *g_srv = NULL;

/* Simple logger callback for demo */
static void demo_logger(ws_log_level level, const char *msg, void *user) {
  (void)user;
  const char *lvl = (level == WS_LOG_ERROR) ? "ERROR" :
                    (level == WS_LOG_WARN)  ? "WARN"  :
                    (level == WS_LOG_INFO)  ? "INFO"  : "DEBUG";
  fprintf(stderr, "[%s] %s\n", lvl, msg);
}

/* SIGINT handler: request graceful shutdown */
static void sigint_handler(int sig) {
  (void)sig;
  if (g_srv) (void)ws_server_request_shutdown(g_srv);
}

/* ----------------------- Handlers (new API signature) -------------------- */

/**
 * @brief Handler for GET /
 */
static int hello_handler(const ws_request *req, void *user) {
  (void)user;
  static const char BODY[] = "Hello, World\n";
  return (int)ws_send_response(req, 200, "OK", "text/plain; charset=utf-8",
                               BODY, sizeof(BODY) - 1);
}

/**
 * @brief Handler for GET /health
 */
static int health_handler(const ws_request *req, void *user) {
  (void)user;
  static const char BODY[] = "OK\n";
  return (int)ws_send_response(req, 200, "OK", "text/plain; charset=utf-8",
                               BODY, sizeof(BODY) - 1);
}

/**
 * @brief Handler for GET /metrics (demo metrics endpoint).
 */
static int metrics_handler(const ws_request *req, void *user) {
  (void)user;
  ws_server *s = req ? req->server : NULL;
  if (!s) {
    static const char BODY[] = "metrics unavailable\n";
    return (int)ws_send_response(req, 500, "Internal Server Error",
                                 "text/plain; charset=utf-8",
                                 BODY, sizeof(BODY) - 1);
  }
  ws_metrics m;
  if (ws_server_get_metrics(s, &m) != 0) {
    static const char BODY[] = "metrics error\n";
    return (int)ws_send_response(req, 500, "Internal Server Error",
                                 "text/plain; charset=utf-8",
                                 BODY, sizeof(BODY) - 1);
  }
  char body[768];
  int n = snprintf(body, sizeof body,
                   "accepted: %llu\n"
                   "enqueued: %llu\n"
                   "dequeued: %llu\n"
                   "dropped_new: %llu\n"
                   "dropped_oldest: %llu\n"
                   "bytes_sent: %llu\n"
                   "resp_2xx: %llu\n"
                   "resp_3xx: %llu\n"
                   "resp_4xx: %llu\n"
                   "resp_5xx: %llu\n"
                   "queue_len: %zu\n"
                   "queue_peak: %zu\n"
                   "threads: %u\n",
                   (unsigned long long)m.accepted,
                   (unsigned long long)m.enqueued,
                   (unsigned long long)m.dequeued,
                   (unsigned long long)m.dropped_new,
                   (unsigned long long)m.dropped_oldest,
                   (unsigned long long)m.bytes_sent,
                   (unsigned long long)m.responses_2xx,
                   (unsigned long long)m.responses_3xx,
                   (unsigned long long)m.responses_4xx,
                   (unsigned long long)m.responses_5xx,
                   m.queue_len, m.queue_max_observed, m.nthreads);
  if (n < 0) return -1;
  return (int)ws_send_response(req, 200, "OK", "text/plain; charset=utf-8",
                               body, (size_t)n);
}

/**
 * @brief Program entry point for the demo app.
 *
 * Usage:
 *   webserver-demo [-p PORT] [-t THREADS] [-q QUEUE] [-b BACKLOG]
 *                  [--keepalive 0|1] [--ka-timeout MS] [--ka-max-req N]
 *                  [--queue-policy block|drop-new|drop-oldest]
 *
 * Defaults:
 *   PORT=8080, THREADS=library default (cores, at least 2)
 *
 * @param[in]  argc  Argument count.
 * @param[in]  argv  Argument vector.
 * @retval 0 on success
 * @retval 2 on usage or invalid parameters
 * @retval 1 on runtime error
 */
int main(int argc, char **argv) {
  unsigned short port = 8080;
  unsigned int nthreads = 0; /* 0 -> use library default */
  size_t queue_cap = 0;      /* 0 -> library default */
  int backlog = 0;           /* 0 -> SOMAXCONN */
  int enable_ka = 0;
  int ka_timeout_ms = 15000;
  int ka_max_req = 100;
  ws_log_level log_level = WS_LOG_INFO;
  ws_queue_policy policy = WS_QUEUE_BLOCK;

  for (int i = 1; i < argc; ++i) {
    if (strcmp(argv[i], "-p") == 0 || strcmp(argv[i], "--port") == 0) {
      if (i + 1 >= argc) {
        fprintf(stderr, "Missing value for %s\n", argv[i]);
        return 2;
      }
      if (parse_port(argv[i + 1], &port) != 0) {
        fprintf(stderr, "Invalid port: %s\n", argv[i + 1]);
        return 2;
      }
      i++;
    } else if (strcmp(argv[i], "-t") == 0 || strcmp(argv[i], "--threads") == 0) {
      if (i + 1 >= argc) {
        fprintf(stderr, "Missing value for %s\n", argv[i]);
        return 2;
      }
      char *end = NULL;
      errno = 0;
      unsigned long v = strtoul(argv[i + 1], &end, 10);
      if (errno != 0 || end == argv[i + 1] || *end != '\0' || v > 1024UL || v == 0) {
        fprintf(stderr, "Invalid thread count: %s\n", argv[i + 1]);
        return 2;
      }
      nthreads = (unsigned int)v;
      i++;
    } else if (strcmp(argv[i], "-q") == 0 || strcmp(argv[i], "--queue") == 0) {
      if (i + 1 >= argc) { fprintf(stderr, "Missing value for %s\n", argv[i]); return 2; }
      char *end = NULL; errno = 0; unsigned long v = strtoul(argv[i + 1], &end, 10);
      if (errno != 0 || end == argv[i + 1] || *end != '\0' || v == 0 || v > 1UL<<30) {
        fprintf(stderr, "Invalid queue capacity: %s\n", argv[i + 1]); return 2;
      }
      queue_cap = (size_t)v; i++;
    } else if (strcmp(argv[i], "-b") == 0 || strcmp(argv[i], "--backlog") == 0) {
      if (i + 1 >= argc) { fprintf(stderr, "Missing value for %s\n", argv[i]); return 2; }
      char *end = NULL; errno = 0; long v = strtol(argv[i + 1], &end, 10);
      if (errno != 0 || end == argv[i + 1] || *end != '\0' || v <= 0 || v > 65535) {
        fprintf(stderr, "Invalid backlog: %s\n", argv[i + 1]); return 2;
      }
      backlog = (int)v; i++;
    } else if (strcmp(argv[i], "--keepalive") == 0) {
      if (i + 1 >= argc) { fprintf(stderr, "Missing value for %s\n", argv[i]); return 2; }
      enable_ka = (strcmp(argv[i + 1], "1") == 0) ? 1 : 0; i++;
    } else if (strcmp(argv[i], "--ka-timeout") == 0) {
      if (i + 1 >= argc) { fprintf(stderr, "Missing value for %s\n", argv[i]); return 2; }
      char *end = NULL; errno = 0; long v = strtol(argv[i + 1], &end, 10);
      if (errno != 0 || end == argv[i + 1] || *end != '\0' || v <= 0 || v > 600000) {
        fprintf(stderr, "Invalid ka-timeout: %s\n", argv[i + 1]); return 2;
      }
      ka_timeout_ms = (int)v; i++;
    } else if (strcmp(argv[i], "--ka-max-req") == 0) {
      if (i + 1 >= argc) { fprintf(stderr, "Missing value for %s\n", argv[i]); return 2; }
      char *end = NULL; errno = 0; long v = strtol(argv[i + 1], &end, 10);
      if (errno != 0 || end == argv[i + 1] || *end != '\0' || v <= 0 || v > 1000000) {
        fprintf(stderr, "Invalid ka-max-req: %s\n", argv[i + 1]); return 2;
      }
      ka_max_req = (int)v; i++;
    } else if (strcmp(argv[i], "--queue-policy") == 0) {
      if (i + 1 >= argc) { fprintf(stderr, "Missing value for %s\n", argv[i]); return 2; }
      const char *val = argv[i + 1];
      if (strcmp(val, "block") == 0) policy = WS_QUEUE_BLOCK;
      else if (strcmp(val, "drop-new") == 0) policy = WS_QUEUE_DROP_NEW;
      else if (strcmp(val, "drop-oldest") == 0) policy = WS_QUEUE_DROP_OLDEST;
      else {
        fprintf(stderr, "Invalid queue-policy: %s (expected block|drop-new|drop-oldest)\n", val);
        return 2;
      }
      i++;
    } else {
      fprintf(stderr, "Usage: %s [-p PORT] [-t THREADS] [-q QUEUE] [-b BACKLOG] [--keepalive 0|1] [--ka-timeout MS] [--ka-max-req N] [--queue-policy block|drop-new|drop-oldest]\n", argv[0]);
      return 2;
    }
  }

  /* Build options */
  ws_server_opts opts;
  memset(&opts, 0, sizeof opts);
  opts.port = port;
  opts.nthreads = nthreads;
  opts.queue_capacity = queue_cap;
  opts.backlog = backlog;
  opts.enable_keepalive = enable_ka;
  opts.keepalive_timeout_ms = ka_timeout_ms;
  opts.max_keepalive_requests = ka_max_req;
  opts.log_fn = demo_logger;
  opts.log_user = NULL;
  opts.log_level = log_level;
  opts.log_to_stderr = 1;        /* enable default stderr logger as fallback */
  opts.log_format = NULL;
  opts.queue_policy = policy;

  ws_server *s = ws_server_new_with_opts(&opts);
  g_srv = s;
  /* Install SIGINT handler for graceful shutdown */
  signal(SIGINT, sigint_handler);
  if (!s) {
    fprintf(stderr, "Failed to create server\n");
    return 1;
  }

  if (ws_server_add_route(s, "GET", "/", hello_handler, NULL) != 0 ||
      ws_server_add_route(s, "GET", "/health", health_handler, NULL) != 0 ||
      ws_server_add_route(s, "GET", "/metrics", metrics_handler, NULL) != 0) {
    fprintf(stderr, "Failed to register routes\n");
    ws_server_free(s);
    return 1;
  }

  int rc = ws_server_run(s);
  ws_server_free(s);
  return (rc == 0) ? 0 : 1;
}
