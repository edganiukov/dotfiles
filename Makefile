all: neovim

neovim:
	[ -f ~/.config/nvim/init.vim ] || mkdir -p ~/.config/nvim && ln -s $(PWD)/init.vim ~/.config/nvim/init.vim
	[ -f ~/.config/nvim/autoload/plug.vim ] || curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs \
		https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

clean:
	[ -f ~/.config/nvim/init.vim ] || rm -f ~/.config/nvim/init.vim
	[ -f ~/.config/nvim/autoload/plug.vim ] &&  rm -f ~/.config/nvim/autoload/plug.vim

.PHONY: all, neovim, clean
