/**
 * @file handlers0.h
 * @brief Internal handler interfaces and types (not exported).
 * @ingroup router
 */

#ifndef HANDLERS0_H
#define HANDLERS0_H


#include <stddef.h>

/**
 * @brief Output of a handler function.
 */
typedef struct handler_out {
  int status;               /**< HTTP status code. */
  const char *reason;       /**< Reason phrase. */
  const char *content_type; /**< MIME type. */
  const char *body;         /**< Pointer to body bytes. */
  size_t body_len;          /**< Length of body. */
} handler_out;

/**
 * @brief Handler for GET /
 * @param out Output structure to populate.
 */
void handler_root(handler_out *out);

/**
 * @brief Handler for GET /health
 * @param out Output structure to populate.
 */
void handler_health(handler_out *out);

#endif /* HANDLERS0_H */
