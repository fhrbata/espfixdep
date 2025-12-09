#include "utils.h"
#include <io.h>
#include <windows.h>

char* EOL = "\r\n";

int run_process(char* argv[]) {
	STARTUPINFO si;
	PROCESS_INFORMATION pi;
	DWORD exitCode = 0;
	char* cmdl;
	char* cmdl_orig;

	cmdl_orig = GetCommandLine();
	cmdl = strchr(cmdl_orig, ' ');
	while (*cmdl == ' ')
		cmdl++;

	if (!cmdl)
		die("Invalid command line '%s'", cmdl_orig);

	ZeroMemory(&si, sizeof(si));
	si.cb = sizeof(si);
	ZeroMemory(&pi, sizeof(pi));

	if (!CreateProcess(NULL, cmdl, NULL, NULL, FALSE, 0, NULL, NULL, &si,
			   &pi))
		die("CreateProcess '%s' failed (%lu)", cmdl, GetLastError());

	WaitForSingleObject(pi.hProcess, INFINITE);

	if (!GetExitCodeProcess(pi.hProcess, &exitCode))
		die("GetExitCodeProcess '%s' failed (%lu)", cmdl,
		    GetLastError());

	CloseHandle(pi.hProcess);
	CloseHandle(pi.hThread);

	return exitCode;
}

int file_exists(char* fn) { return _access(fn, 0) != -1; }
