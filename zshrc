# exports
export GOPATH=$HOME/go:$HOME/dev/go:$HOME/work/go
export GOARCH=amd64
export GOOS=linux
export PATH=$PATH:$HOME/go/bin

export GPG_TTY=$(tty)
export LPASS_CLIPBOARD_COMMAND="xclip -selection primary -in -l 1"
export EDITOR=nvim

export CDPATH=.:~:~/dev/go/src/github.com/edganiukov:~/work/go/src/github.com/lovoo

 #Set LS_COLORS
if [[ -f ~/.dir_colors ]]; then
    eval `dircolors -b ~/.dir_colors`
fi

# History settings
HISTFILE=~/.histfile
HISTSIZE=3000
SAVEHIST=3000
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt NO_HIST_BEEP
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_SAVE_NO_DUPS
setopt HIST_FIND_NO_DUPS
setopt SHARE_HISTORY
setopt HIST_VERIFY

setopt extended_glob
setopt noequals
setopt nobeep
setopt autocd
setopt nohup
setopt HASH_CMDS

# compinstall
autoload -Uz compinit
compinit

zstyle ':completion:*' completer _expand _complete _ignored
zstyle :compinstall filename '/home/ed/.zshrc'
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# binds
bindkey "^[[2~" yank
bindkey "^[[3~" delete-char
bindkey "^[[7~" beginning-of-line
bindkey "^[[8~" end-of-line
bindkey "^[[A"  up-line-or-history
bindkey "^[[B"  down-line-or-history
bindkey "^[[H"  beginning-of-line
bindkey "^[[F"  end-of-line
bindkey "^[e"   expand-cmd-path
bindkey "^[[1~" beginning-of-line
bindkey "^[[4~" end-of-line
bindkey " "     magic-space
bindkey "^[u"   undo
bindkey "^[r"   redo
bindkey "\e[A" history-search-backward
bindkey "\e[B" history-search-forward

# aliases
alias ls='ls -h --color=auto --group-directories-first'
alias df='df -m'
alias lsl='ls -hl --color=auto --group-directories-first'

alias mv='mv -i'
alias cp='cp -Ri'
alias rm='rm -rI'
alias rmf='rm -f'
alias rmrf='rm -fR'

alias tmux="tmux -u2"
alias wget="wget --continue --content-disposition"
alias vim="nvim"
alias grep="grep --colour"
alias k='kubectl'

# prompt
autoload -Uz vcs_info
autoload -U promptinit
promptinit

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git*' formats "[%b]"
precmd() {
    vcs_info
}
setopt prompt_subst

PROMPT='[%F{green}%n%f@%F{blue}%m%f] %F{yellow}%1~%f %F{blue}${vcs_info_msg_0_}%f %# '
RPROMPT='[%F{yellow}%*%f]'

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
