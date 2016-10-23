all: neovim

vim:
	[ -f ~/.vimrc ] || mkdir -p ~/.vim && ln -s $(PWD)/init.vim ~/.vimrc
	[ -f ~/.vim/autoload/plug.vim ] || curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
		https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

neovim:
	[ -f ~/.config/nvim/init.vim ] || mkdir -p ~/.config/nvim && ln -s $(PWD)/init.vim ~/.config/nvim/init.vim
	[ -f ~/.config/nvim/autoload/plug.vim ] || curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs \
		https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

clean:
	[ -L ~/.vimrc ] && rm -f ~/.vimrc
	[ -f ~/.vim/autoload/plug.vim ] &&  rm -f ~/.vim/autoload/plug.vim
	[ -L ~/.config/nvim/init.vim ] && rm -f ~/.config/nvim/init.vim
	[ -f ~/.config/nvim/autoload/plug.vim ] &&  rm -f ~/.config/nvim/autoload/plug.vim

.PHONY: all, vim, neovim, clean
