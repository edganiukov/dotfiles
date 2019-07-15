CWD=$(shell pwd)

all: clean, nvim, tmux, git, zsh

nvim:
	mkdir -p ~/.config/nvim && \
		ln -s $(CWD)/init.vim $(HOME)/.config/nvim/init.vim
	curl -sfLo $(HOME)/.config/nvim/autoload/plug.vim --create-dirs \
		https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

vim:
	ln -s $(CWD)/init.vim $(HOME)/.vimrc
	curl -sfLo $(HOME)/.vim/autoload/plug.vim --create-dirs \
		https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

tmux:
	ln -s $(CWD)/tmux.conf $(HOME)/.tmux.conf
	mkdir -p $(HOME)/.tmux/plugins && \
		git clone https://github.com/tmux-plugins/tpm $(HOME)/.tmux/plugins/tpm

git:
	ln -s $(CWD)/gitconfig $(HOME)/.gitconfig

zsh:
	ln -s $(CWD)/zshrc $(HOME)/.zshrc
	ln -s $(CWD)/zsh $(HOME)/.zsh

terminal:
	ln -s $(CWD)/alacritty.yml $(HOME)/.config/alacritty/alacritty.yml

awesome:
	ln -s $(CWD)/awesome $(HOME)/.config/awesome

x:
	ln -s $(CWD)/Xresources $(HOME)/.Xresources
	ln -s $(CWD)/xinitrc $(HOME)/.xinitrc

clean:
	rm -rf $(HOME)/.config/nvim
	rm -rf $(HOME)/.vim
	rm -f $(HOME)/.vimrc
	rm -rf $(HOME)/.tmux/plugins
	rm -f $(HOME)/.tmux.conf
	rm -f $(HOME)/.gitconfig
	rm -rf $(HOME)/.zsh-pugins
	rm -f $(HOME)/.zshrc
	rm -f $(HOME)/.alacritty.yml
	rm -rf $(HOME)/.config/awesome
	rm -f $(HOME)/.Xresources
	rm -f $(HOME)/.xinitrc

.PHONY: all, nvim, vim, tmux, git, zsh, awesome, x, clean
