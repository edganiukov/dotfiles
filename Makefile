CWD=$(shell pwd)

all: clean, vim, tmux, awesome, cli, vimperator

nvim:
	mkdir -p ~/.config/nvim && ln -s $(CWD)/init.vim $(HOME)/.config/nvim/init.vim
	curl -fLo $(HOME)/.config/nvim/autoload/plug.vim --create-dirs \
		https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

tmux:
	ln -s $(CWD)/tmux.conf $(HOME)/.tmux.conf
	ln -s $(CWD)/urlview $(HOME)/.urlview
	mkdir -p $(HOME)/.tmux/plugins && git clone https://github.com/tmux-plugins/tpm $(HOME)/.tmux/plugins/tpm

awesome:
	ln -s $(CWD)/awesome $(HOME)/.config/awesome

cli:
	ln -s $(CWD)/Xresources $(HOME)/.Xresources
	ln -s $(CWD)/xinitrc $(HOME)/.xinitrc
	ln -s $(CWD)/dir_colors $(HOME)/.dir_colors
	ln -s $(CWD)/gitconfig $(HOME)/.gitconfig
	ln -s $(CWD)/zshrc $(HOME)/.zshrc

vimperator:
	ln -s $(CWD)/vimperatorrc $(HOME)/.vimperatorrc

irssi:
	mkdir -p $(HOME)/.irssi
	ln -s $(CWD)/irssi/config $(HOME)/.irssi/config
	ln -s $(CWD)/irssi/solarized-universal.theme $(HOME)/.irssi/solarized-universal.theme

clean:
	rm -rf $(HOME)/.config/nvim
	rm -rf $(HOME)/.config/awesome
	rm -rf $(HOME)/.tmux/plugins
	rm -f $(HOME)/.tmux.conf
	rm -f $(HOME)/.Xresources
	rm -f $(HOME)/.xinitrc
	rm -f $(HOME)/.dir_colors
	rm -f $(HOME)/.gitconfig
	rm -f $(HOME)/.vimperatorrc
	rm -f $(HOME)/.zshrc
	rm -f $(HOME)/.irssi

.PHONY: all, nvim, clean, tmux, awesome, cli, vimperatorrc, irssi
