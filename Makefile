all: vim
all: noevim

vim:
	[ -f ~/.config/nvim/autoload/plug.vim ] || curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    	https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	[ -f ~/.vimrc ] || ln -s $(PWD)/vim/vimrc ~/.vimrc

neovim:
	[ -f ~/.config/nvim/init.vim ] || ln -s $(PWD)/vim/vimrc ~/.config/nvim/init.vim
	[ -f ~/.config/nvim/autoload/plug.vim ] || curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs \
	    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

clean:
	[ -f ~/.vimrc ] || rm ~/.vimrc
	[ -f ~/.config/nvim/init.vim ] || rm ~/.config/nvim/init.vim

.PHONY: all, vim, neovim, clean
