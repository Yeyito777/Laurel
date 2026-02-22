PREFIX = $(HOME)/.local

laurel-hotkey: laurel-hotkey.c
	$(CC) -o $@ $< -lX11

install: laurel-hotkey
	mkdir -p $(PREFIX)/bin
	cp laurel-hotkey $(PREFIX)/bin/

uninstall:
	rm -f $(PREFIX)/bin/laurel-hotkey

clean:
	rm -f laurel-hotkey

.PHONY: install uninstall clean
