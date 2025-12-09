#include "utils.h"
#include <ctype.h>

#define DEPS_SIZE 1024 * 10
struct depfile {
	char* data;
	char* target;
	char* sdkconfig_dir;
	char* deps[DEPS_SIZE];
	size_t deps_cnt;
};

#define OPTIONS_SIZE 1024 * 10
struct config {
	char* data;
	char* options[OPTIONS_SIZE];
	size_t options_cnt;
};

char* read_file(char* fn) {
	FILE* fp;
	long size;
	char* buf;

	fp = fopen(fn, "rb");
	if (!fp)
		die_errno("open '%s'", fn);

	if (fseek(fp, 0, SEEK_END))
		die_errno("fseek '%s'", fn);

	size = ftell(fp);
	if (size == -1)
		die_errno("ftell '%s'", fn);

	rewind(fp);

	buf = malloc(size + 1);
	if (!buf)
		die_errno("malloc '%s'", fn);

	if (fread(buf, 1, size, fp) != size)
		die("fread '%s'", fn);

	buf[size] = '\0';

	fclose(fp);

	return buf;
}

char* get_sdkconfig_dir(char* dep) {
	char* c;

	c = strrchr(dep, '/');
	if (!c)
		return NULL;

	if (strcmp(c, "/sdkconfig.h"))
		return NULL;

	*c = '\0';

	return dep;
}

void depfile_add_dep(struct depfile* depfile, char* dep, char* fn) {
	char* sdkconfig_dir;

	if (!*dep)
		return;

	sdkconfig_dir = get_sdkconfig_dir(dep);
	if (sdkconfig_dir)
		depfile->sdkconfig_dir = sdkconfig_dir;
	else
		depfile->deps[depfile->deps_cnt++] = dep;

	if (depfile->deps_cnt == DEPS_SIZE)
		die("insufficient dependencies array size for '%s'", fn);
}

struct depfile* depfile_get(char* fn) {
	static struct depfile depfile;
	char* c;
	char* dep;
	char* colon;
	char last = 0;

	depfile.data = read_file(fn);

	/* read target */
	colon = strchr(depfile.data, ':');
	if (!colon)
		die("cannot find target in '%s'", fn);

	*colon = '\0';
	depfile.target = depfile.data;

	c = colon + 1;
	dep = c;

	/* read target dependencies */
	while (1) {
		if ((*c == '\n' || *c == '\r') && last == '\\') {
			dep = c + 1;

		} else if ((*c == ' ' || *c == '\n' || *c == '\r') &&
			   last != '\\') {
			*c = '\0';
			depfile_add_dep(&depfile, dep, fn);
			dep = c + 1;

		} else if (!*c) {
			depfile_add_dep(&depfile, dep, fn);
			break;
		}

		last = *c++;
	}

	return &depfile;
}

void depfile_put(struct depfile* depfile) { free(depfile->data); }

void config_add_option(struct config* config, char* option, char* fn) {
	char** opts = config->options;
	int i;

	for (i = 0; opts[i]; i++) {
		if (!strcmp(opts[i], option))
			break;
	}

	if (opts[i])
		return;

	if (i == OPTIONS_SIZE)
		die("insufficient config option array size for '%s'", fn);

	config->options[config->options_cnt++] = option;
}

struct config* config_get(char* fn) {
	static struct config config;
	char* prefix = "CONFIG_";
	size_t prefix_len = strlen(prefix);
	char* c;
	char* option;

	config.data = read_file(fn);
	c = config.data;

	while (1) {
		c = strstr(c, prefix);
		if (!c)
			break;

		option = c + prefix_len;
		while (*c && (isupper(*c) || isdigit(*c) || *c == '_'))
			c++;

		if (!*c) {
			config_add_option(&config, option, fn);
			break;
		}

		*c++ = '\0';
		config_add_option(&config, option, fn);
	}

	return &config;
}

void config_put(struct config* config) { free(config->data); }

char* get_dep_fn(int argc, char* argv[]) {
	do {
		if (!strcmp(*argv, "-MF"))
			return *++argv;

	} while (*++argv);

	return NULL;
}

char* get_src_fn(int argc, char* argv[]) { return argv[argc - 1]; }

void fix_dep_file(struct depfile* depfile, struct config* config, char* fn) {
#define MAX_DEP_FN_SIZE 1024 * 32

	static char dep_fn[MAX_DEP_FN_SIZE];
	FILE* fp;
	int i;

	fp = fopen(fn, "wb");
	if (!fp)
		die_errno("open '%s'", fn);

	if (fprintf(fp, "%s:", depfile->target) < 0)
		die_errno("fprintf '%s'", fn);

	for (i = 0; i < depfile->deps_cnt; i++) {
		if (fprintf(fp, " \\%s %s", EOL, depfile->deps[i]) < 0)
			die_errno("fprintf '%s'", fn);
	}

	for (i = 0; i < config->options_cnt; i++) {
		str_to_lower(config->options[i]);
		str_replace_chr(config->options[i], '_', '/');

		if (snprintf(dep_fn, MAX_DEP_FN_SIZE, "%s/%s.h",
			     depfile->sdkconfig_dir,
			     config->options[i]) >= MAX_DEP_FN_SIZE)
			die("snprintf '%s'", fn);

		if (!file_exists(dep_fn))
			continue;

		if (fprintf(fp, " \\%s %s", EOL, dep_fn) < 0)
			die_errno("fprintf '%s'", fn);
	}

	if (fprintf(fp, "%s", EOL) < 0)
		die_errno("fprintf '%s'", fn);

	fclose(fp);

#undef MAX_DEP_FN_SIZE
}

int main(int argc, char* argv[]) {
	struct depfile* depfile;
	struct config* config;
	char* dep_fn;
	char* src_fn;
	int rv;

	if (argc < 2) {
		fprintf(stderr, "version: %s\n", VERSION);
		fprintf(stderr, "usage: espfixdep <cmd> <arg...>\n");
		return 1;
	}

	rv = run_process(argv);
	if (rv)
		die("run_process exited with error code: %d", rv);

	dep_fn = get_dep_fn(argc, argv);
	if (!dep_fn)
		return 0;

	src_fn = get_src_fn(argc, argv);
	if (!src_fn)
		return 0;

	depfile = depfile_get(dep_fn);
	if (!depfile->sdkconfig_dir) {
		depfile_put(depfile);
		return 0;
	}

	config = config_get(src_fn);

	fix_dep_file(depfile, config, dep_fn);

	config_put(config);
	depfile_put(depfile);

	return 0;
}
