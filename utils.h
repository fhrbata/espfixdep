#ifndef _UTILS_H_
#define _UTILS_H_

#include <ctype.h>
#include <errno.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static inline void die_msg(char* file, int line, const char* func,
			   int add_errno, char* fmt, ...) {
	va_list ap;

	fprintf(stderr, "%s:%d: in %s: ", file, line, func);

	va_start(ap, fmt);
	vfprintf(stderr, fmt, ap);
	va_end(ap);

	if (add_errno)
		fprintf(stderr, ": %s (%d)\n", strerror(errno), errno);
	else
		fprintf(stderr, "\n");

	exit(EXIT_FAILURE);
}

#define die(...) die_msg(__FILE__, __LINE__, __func__, 0, __VA_ARGS__)
#define die_errno(...) die_msg(__FILE__, __LINE__, __func__, 1, __VA_ARGS__)

int run_process(char* argv[]);
int file_exists(char* fn);

static inline void str_to_lower(char* s) {
	while (*s) {
		*s = tolower(*s);
		s++;
	}
}

static inline void str_replace_chr(char* s, char from, char to) {
	while (*s) {
		if (*s == from)
			*s = to;
		s++;
	}
}

extern char* EOL;

#endif
