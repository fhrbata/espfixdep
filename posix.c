#include "utils.h"
#include <sys/wait.h>
#include <unistd.h>

char* EOL = "\n";

int run_process(char* argv[]) {
	pid_t pid;
	int status;

	pid = fork();
	if (pid == -1)
		die_errno("fork");

	if (pid == 0) {
		if (execvp(argv[1], &argv[1]) == -1)
			die_errno("execvp: '%s'", argv[1]);
	}

	if (waitpid(pid, &status, 0) == -1)
		die_errno("waitpid: '%s'", argv[1]);

	if (WIFEXITED(status))
		return WEXITSTATUS(status);

	if (WIFSIGNALED(status))
		return WTERMSIG(status);

	return 0;
}

int file_exists(char* fn) { return access(fn, F_OK) == 0; }
