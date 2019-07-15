.PHONY: nvim, vim, tmux, git, zsh, x, clean, i3, awesome

CWD=$(shell pwd)

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
	cp $(CWD)/gitconfig $(HOME)/.gitconfig

zsh:
	ln -s $(CWD)/zshrc $(HOME)/.zshrc
	ln -s $(CWD)/zsh $(HOME)/.zsh

terminal:
	ln -s $(CWD)/alacritty.yml $(HOME)/.config/alacritty/alacritty.yml

x:
	ln -s $(CWD)/Xresources $(HOME)/.Xresources
	ln -s $(CWD)/xinitrc $(HOME)/.xinitrc

i3:
	ln -s $(CWD)/i3 $(HOME)/.config/i3
	ln -s $(CWD)/rofi $(HOME)/.config/rofi

awesome:
	ln -s $(CWD)/awesome $(HOME)/.config/awesome

clean:
	rm -rf $(HOME)/.config/nvim
	rm -rf $(HOME)/.vim
	rm -f $(HOME)/.vimrc
	rm -rf $(HOME)/.tmux
	rm -f $(HOME)/.tmux.conf
	rm -f $(HOME)/.gitconfig
	rm -rf $(HOME)/.zsh
	rm -f $(HOME)/.zshrc
	rm -f $(HOME)/.alacritty.yml
	rm -f $(HOME)/.Xresources
	rm -f $(HOME)/.xinitrc
	rm -rf $(HOME)/.config/i3
	rm -rf $(HOME)/.config/rofi
	rm -rf $(HOME)/.config/awesome

