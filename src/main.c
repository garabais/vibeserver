/**
 * @file main.c
 * @brief Entry point for the C webserver.
 * @ingroup server
 */

#include "server.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

/**
 * @brief Parse a TCP port (uint16) from a decimal string.
 *
 * Accepts values in the range [0, 65535].
 *
 * @param s Null-terminated string containing the port number.
 * @param out_port Output location for the parsed port on success.
 * @retval 0 on success
 * @retval -1 on error (invalid format or out of range)
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

/**
 * @brief Program entry point.
 *
 * Usage:
 *   webserver [-p PORT]
 *
 * Defaults to port 8080 if not specified.
 */
int main(int argc, char **argv) {
  unsigned short port = 8080;

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
    } else {
      fprintf(stderr, "Usage: %s [-p PORT]\n", argv[0]);
      return 2;
    }
  }

  return server_run(port);
}
