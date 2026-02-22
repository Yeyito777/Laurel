/* laurel-hotkey — grab a global X hotkey and signal a process on press
 *
 * Usage: laurel-hotkey <pidfile> [key] [modifier]
 *   pidfile   — file containing the PID to send SIGUSR1 to
 *   key       — X key name for XStringToKeysym (default: g)
 *   modifier  — super, alt, ctrl, shift, or combos like super+shift (default: super)
 *
 * Compile: cc -o laurel-hotkey laurel-hotkey.c -lX11
 */

#include <X11/Xlib.h>
#include <X11/keysym.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static Display *dpy;
static int running = 1;

static void cleanup(int sig) {
	(void)sig;
	running = 0;
}

static unsigned int parse_mod(const char *s) {
	unsigned int mask = 0;
	if (!strcmp(s, "none") || !*s)
		return 0;
	char buf[64];
	snprintf(buf, sizeof(buf), "%s", s);
	for (char *tok = strtok(buf, "+"); tok; tok = strtok(NULL, "+")) {
		if (!strcmp(tok, "super"))       mask |= Mod4Mask;
		else if (!strcmp(tok, "alt"))    mask |= Mod1Mask;
		else if (!strcmp(tok, "ctrl"))   mask |= ControlMask;
		else if (!strcmp(tok, "shift"))  mask |= ShiftMask;
		else fprintf(stderr, "laurel-hotkey: unknown modifier '%s'\n", tok);
	}
	return mask;
}

static pid_t read_pid(const char *path) {
	FILE *f = fopen(path, "r");
	if (!f) return -1;
	pid_t pid;
	if (fscanf(f, "%d", &pid) != 1) pid = -1;
	fclose(f);
	return pid;
}

static void grab(Window root, unsigned int mod, KeyCode code) {
	/* Grab with every combination of lock masks */
	unsigned int locks[] = { 0, LockMask, Mod2Mask, LockMask | Mod2Mask };
	for (int i = 0; i < 4; i++)
		XGrabKey(dpy, code, mod | locks[i], root, True, GrabModeAsync, GrabModeAsync);
}

static void ungrab(Window root, unsigned int mod, KeyCode code) {
	unsigned int locks[] = { 0, LockMask, Mod2Mask, LockMask | Mod2Mask };
	for (int i = 0; i < 4; i++)
		XUngrabKey(dpy, code, mod | locks[i], root);
}

int main(int argc, char *argv[]) {
	if (argc < 2) {
		fprintf(stderr, "usage: laurel-hotkey <pidfile> [key] [modifier]\n");
		return 1;
	}

	const char *pidfile = argv[1];
	const char *keyname = argc > 2 ? argv[2] : "g";
	const char *modname = argc > 3 ? argv[3] : "super";

	dpy = XOpenDisplay(NULL);
	if (!dpy) {
		fprintf(stderr, "laurel-hotkey: cannot open display\n");
		return 1;
	}

	KeySym sym = XStringToKeysym(keyname);
	if (sym == NoSymbol) {
		fprintf(stderr, "laurel-hotkey: unknown key '%s'\n", keyname);
		return 1;
	}

	KeyCode code = XKeysymToKeycode(dpy, sym);
	unsigned int mod = parse_mod(modname);
	Window root = DefaultRootWindow(dpy);

	grab(root, mod, code);
	XSelectInput(dpy, root, KeyPressMask);

	signal(SIGTERM, cleanup);
	signal(SIGINT, cleanup);

	XEvent ev;
	while (running) {
		XNextEvent(dpy, &ev);
		if (ev.type == KeyPress) {
			pid_t pid = read_pid(pidfile);
			if (pid > 0)
				kill(pid, SIGUSR1);
		}
	}

	ungrab(root, mod, code);
	XCloseDisplay(dpy);
	return 0;
}
