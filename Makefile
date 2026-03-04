PREFIX = /usr
SYSCONFDIR = /etc

laurel-hotkey: laurel-hotkey.c
	$(CC) -o $@ $< -lX11

install: laurel-hotkey
	install -Dm755 laurel-replay $(DESTDIR)$(PREFIX)/bin/laurel-replay
	install -Dm755 laurel-clip $(DESTDIR)$(PREFIX)/bin/laurel-clip
	install -Dm755 laurel-hotkey $(DESTDIR)$(PREFIX)/bin/laurel-hotkey
	install -Dm644 config.sh $(DESTDIR)$(SYSCONFDIR)/laurel/config.sh
	install -Dm644 clip-template.html $(DESTDIR)$(PREFIX)/share/laurel/clip-template.html
	install -Dm644 clip.mp3 $(DESTDIR)$(PREFIX)/share/laurel/clip.mp3
	install -Dm644 laurel-replay.service $(DESTDIR)$(PREFIX)/lib/systemd/user/laurel-replay.service

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/laurel-replay
	rm -f $(DESTDIR)$(PREFIX)/bin/laurel-clip
	rm -f $(DESTDIR)$(PREFIX)/bin/laurel-hotkey
	rm -f $(DESTDIR)$(SYSCONFDIR)/laurel/config.sh
	rm -f $(DESTDIR)$(PREFIX)/share/laurel/clip-template.html
	rm -f $(DESTDIR)$(PREFIX)/share/laurel/clip.mp3
	rm -f $(DESTDIR)$(PREFIX)/lib/systemd/user/laurel-replay.service

clean:
	rm -f laurel-hotkey

.PHONY: install uninstall clean
