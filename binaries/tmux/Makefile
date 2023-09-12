TARGETDIR ?= /tmp/tmux

all: prep libevent ncurses tmux copy clean

prep:
	mkdir -p $(TARGETDIR)

libevent: prep
	cd $(TARGETDIR) && \
	curl -L https://github.com/libevent/libevent/releases/download/release-2.0.22-stable/libevent-2.0.22-stable.tar.gz | tar -zxvf - && \
 	cd libevent-2.0.22-stable && \
 	./configure --prefix=$(TARGETDIR) && make && make install

ncurses: prep
	cd $(TARGETDIR) && \
  curl -L https://ftp.gnu.org/pub/gnu/ncurses/ncurses-6.0.tar.gz | tar -zxvf - && \
	cd ncurses-6.0 && \
	./configure --prefix $(TARGETDIR) \
              --with-normal --with-termlib \
              --with-default-terminfo-dir=/usr/share/terminfo \
              --with-terminfo-dirs="/etc/terminfo:/lib/terminfo:/usr/share/terminfo" \
              --enable-pc-files \
              --with-pkg-config-libdir=$(TARGETDIR)/lib/pkgconfig \
  && make && make install

tmux: libevent ncurses
	cd $(TARGETDIR) && \
	curl -L https://github.com/tmux/tmux/releases/download/3.1c/tmux-3.1c.tar.gz | tar zxvf - && \
	cd tmux-3.1c && \
	PKG_CONFIG_PATH=$(TARGETDIR)/lib/pkgconfig ./configure --enable-static --prefix=$(TARGETDIR) && make && make install 

copy:
	cp $(TARGETDIR)/bin/tmux .

clean:
	rm -rf $(TARGETDIR)
