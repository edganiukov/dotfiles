install:
	[ -f ~/.vimrc ] || ln -s $(PWD)/vim/vimrc ~/.vimrc
	[ -f ~/.config/nvim/init.vim ] || ln -s $(PWD)/vim/vimrc ~/.config/nvim/init.vim
	[ -d ~/.config/nvim/autoload ] || ln -s $(PWD)/vim/autoload ~/.config/nvim/autoload

clean:
	[ -f ~/.vimrc ] || rm ~/.vimrc
	[ -f ~/.config/nvim/init.vim ] || rm ~/.config/nvim/init.vim
	[ -d ~/.config/nvim/autoload ] || rm ~/.config/nvim/autoload

.PHONY: install, clean
