/**
 * @file handlers.c
 * @brief Example request handlers.
 * @ingroup router
 */

#include "if/handlers0.h"

/**
 * @brief Handler for GET /
 * @param out Output structure to populate.
 */
void handler_root(handler_out *out) {
  static const char BODY[] = "Hello, World\n";
  out->status = 200;
  out->reason = "OK";
  out->content_type = "text/plain; charset=utf-8";
  out->body = BODY;
  out->body_len = sizeof(BODY) - 1;
}

/**
 * @brief Handler for GET /health
 * @param out Output structure to populate.
 */
void handler_health(handler_out *out) {
  static const char BODY[] = "OK\n";
  out->status = 200;
  out->reason = "OK";
  out->content_type = "text/plain; charset=utf-8";
  out->body = BODY;
  out->body_len = sizeof(BODY) - 1;
}
