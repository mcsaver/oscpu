/* SPDX-License-Identifier: MulanPSL-2.0 */

#include <X11/Xlib.h>
#include <X11/extensions/XTest.h>
#include <X11/keysym.h>

#include <errno.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

typedef struct {
  KeySym sym;
  bool shift;
} KeyStroke;

static void usage(const char *program) {
  fprintf(stderr,
      "usage: %s --title SUBSTRING [--text TEXT] [--delay-us N] "
      "[--wait-seconds N] [--find-only]\n",
      program);
}

static bool window_title_contains(Display *display, Window window,
    const char *needle) {
  char *title = NULL;
  if (!XFetchName(display, window, &title) || title == NULL) return false;
  bool matches = strstr(title, needle) != NULL;
  XFree(title);
  return matches;
}

static Window find_window(Display *display, Window root, const char *needle) {
  if (window_title_contains(display, root, needle)) return root;

  Window root_return = None;
  Window parent_return = None;
  Window *children = NULL;
  unsigned int child_count = 0;
  if (!XQueryTree(display, root, &root_return, &parent_return,
      &children, &child_count)) {
    return None;
  }

  Window found = None;
  for (unsigned int i = 0; i < child_count && found == None; i++) {
    found = find_window(display, children[i], needle);
  }
  if (children != NULL) XFree(children);
  return found;
}

static bool key_stroke_for_char(unsigned char ch, KeyStroke *stroke) {
  stroke->shift = false;
  if (ch >= 'a' && ch <= 'z') {
    stroke->sym = XK_a + (ch - 'a');
    return true;
  }
  if (ch >= 'A' && ch <= 'Z') {
    stroke->sym = XK_a + (ch - 'A');
    stroke->shift = true;
    return true;
  }
  if (ch >= '0' && ch <= '9') {
    stroke->sym = XK_0 + (ch - '0');
    return true;
  }

  switch (ch) {
    case '\n': case '\r': stroke->sym = XK_Return; return true;
    case '\t': stroke->sym = XK_Tab; return true;
    case ' ': stroke->sym = XK_space; return true;
    case '-': stroke->sym = XK_minus; return true;
    case '_': stroke->sym = XK_minus; stroke->shift = true; return true;
    case '=': stroke->sym = XK_equal; return true;
    case '+': stroke->sym = XK_equal; stroke->shift = true; return true;
    case '[': stroke->sym = XK_bracketleft; return true;
    case '{': stroke->sym = XK_bracketleft; stroke->shift = true; return true;
    case ']': stroke->sym = XK_bracketright; return true;
    case '}': stroke->sym = XK_bracketright; stroke->shift = true; return true;
    case '\\': stroke->sym = XK_backslash; return true;
    case '|': stroke->sym = XK_backslash; stroke->shift = true; return true;
    case ';': stroke->sym = XK_semicolon; return true;
    case ':': stroke->sym = XK_semicolon; stroke->shift = true; return true;
    case '\'': stroke->sym = XK_apostrophe; return true;
    case '"': stroke->sym = XK_apostrophe; stroke->shift = true; return true;
    case '`': stroke->sym = XK_grave; return true;
    case '~': stroke->sym = XK_grave; stroke->shift = true; return true;
    case ',': stroke->sym = XK_comma; return true;
    case '<': stroke->sym = XK_comma; stroke->shift = true; return true;
    case '.': stroke->sym = XK_period; return true;
    case '>': stroke->sym = XK_period; stroke->shift = true; return true;
    case '/': stroke->sym = XK_slash; return true;
    case '?': stroke->sym = XK_slash; stroke->shift = true; return true;
    case '!': stroke->sym = XK_1; stroke->shift = true; return true;
    case '@': stroke->sym = XK_2; stroke->shift = true; return true;
    case '#': stroke->sym = XK_3; stroke->shift = true; return true;
    case '$': stroke->sym = XK_4; stroke->shift = true; return true;
    case '%': stroke->sym = XK_5; stroke->shift = true; return true;
    case '^': stroke->sym = XK_6; stroke->shift = true; return true;
    case '&': stroke->sym = XK_7; stroke->shift = true; return true;
    case '*': stroke->sym = XK_8; stroke->shift = true; return true;
    case '(': stroke->sym = XK_9; stroke->shift = true; return true;
    case ')': stroke->sym = XK_0; stroke->shift = true; return true;
    default: return false;
  }
}

static bool inject_text(Display *display, const char *text,
    unsigned long delay_us) {
  KeyCode shift = XKeysymToKeycode(display, XK_Shift_L);
  if (shift == 0) return false;

  for (const unsigned char *cursor = (const unsigned char *)text;
       *cursor != '\0'; cursor++) {
    KeyStroke stroke;
    if (!key_stroke_for_char(*cursor, &stroke)) {
      fprintf(stderr, "unsupported input byte 0x%02x\n", *cursor);
      return false;
    }
    KeyCode key = XKeysymToKeycode(display, stroke.sym);
    if (key == 0) {
      fprintf(stderr, "X11 keymap has no keycode for byte 0x%02x\n", *cursor);
      return false;
    }
    if (stroke.shift && !XTestFakeKeyEvent(display, shift, True, CurrentTime))
      return false;
    if (!XTestFakeKeyEvent(display, key, True, CurrentTime) ||
        !XTestFakeKeyEvent(display, key, False, CurrentTime)) {
      return false;
    }
    if (stroke.shift && !XTestFakeKeyEvent(display, shift, False, CurrentTime))
      return false;
    XFlush(display);
    if (delay_us != 0) usleep(delay_us);
  }
  return true;
}

static unsigned long parse_ulong(const char *name, const char *value) {
  errno = 0;
  char *end = NULL;
  unsigned long parsed = strtoul(value, &end, 10);
  if (errno != 0 || end == value || *end != '\0') {
    fprintf(stderr, "invalid %s: %s\n", name, value);
    exit(2);
  }
  return parsed;
}

int main(int argc, char **argv) {
  const char *title = NULL;
  const char *text = NULL;
  unsigned long delay_us = 50000;
  unsigned long wait_seconds = 10;
  bool find_only = false;

  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "--title") == 0 && i + 1 < argc) {
      title = argv[++i];
    } else if (strcmp(argv[i], "--text") == 0 && i + 1 < argc) {
      text = argv[++i];
    } else if (strcmp(argv[i], "--delay-us") == 0 && i + 1 < argc) {
      delay_us = parse_ulong("delay", argv[++i]);
    } else if (strcmp(argv[i], "--wait-seconds") == 0 && i + 1 < argc) {
      wait_seconds = parse_ulong("wait time", argv[++i]);
    } else if (strcmp(argv[i], "--find-only") == 0) {
      find_only = true;
    } else {
      usage(argv[0]);
      return 2;
    }
  }
  if (title == NULL || (!find_only && text == NULL)) {
    usage(argv[0]);
    return 2;
  }

  Display *display = XOpenDisplay(NULL);
  if (display == NULL) {
    fprintf(stderr, "cannot open X11 display\n");
    return 1;
  }

  Window window = None;
  for (unsigned long waited = 0; waited <= wait_seconds * 10; waited++) {
    window = find_window(display, DefaultRootWindow(display), title);
    if (window != None) break;
    usleep(100000);
  }
  if (window == None) {
    fprintf(stderr, "cannot find X11 window whose title contains: %s\n", title);
    XCloseDisplay(display);
    return 1;
  }

  printf("0x%lx\n", window);
  fflush(stdout);
  if (!find_only) {
    XRaiseWindow(display, window);
    XSetInputFocus(display, window, RevertToParent, CurrentTime);
    XSync(display, False);
    if (!inject_text(display, text, delay_us)) {
      fprintf(stderr, "failed to inject X11 key sequence\n");
      XCloseDisplay(display);
      return 1;
    }
    XSync(display, False);
  }
  XCloseDisplay(display);
  return 0;
}
