## ENV vars
###########

# General vars
export PATH=/usr/local/bin:$HOME/.bin:$HOME/.local/bin:$PATH
export LANG=en_US.UTF-8
export GPG_TTY=$(tty)
export EDITOR=nvim
export CLICOLOR=YES
export SHELL=/bin/zsh

# Go vars
export GOPATH=$HOME/.go
export PATH=$GOPATH/bin:$PATH

# Rust vars
[ -f $HOME/.cargo/env ] && source $HOME/.cargo/env
export PATH=$HOME/.cargo/bin:$PATH

# MC vars
export MC_XDG_OPEN=nohup-open

# mpv
export LIBVA_DRIVER_NAME=iHD

# Tex
export TEXMFHOME=$HOME/.texmf
alias tlmgr='/usr/share/texmf-dist/scripts/texlive/tlmgr.pl --usermode --usertree $TEXMFHOME'

## Settings
###########

HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000

setopt append_history
setopt inc_append_history
setopt no_hist_beep
setopt hist_ignore_dups
setopt hist_ignore_all_dups
setopt hist_expire_dups_first
setopt hist_save_no_dups
setopt hist_find_no_dups
setopt hist_reduce_blanks
setopt share_history
setopt hist_verify

setopt extended_glob
setopt noequals
setopt nobeep
setopt autocd
setopt nohup
setopt HASH_CMDS

## Completion
#############

autoload -Uz compinit
compinit

zstyle ':completion:*' completer _expand _complete _ignored
zstyle :compinstall filename '~/.zshrc'
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

## Bindings
###########

# delete
bindkey "^[[3~" delete-char

bindkey "^[e"   expand-cmd-path
bindkey " "     magic-space

# Home/End
bindkey "^[[7~" beginning-of-line
bindkey "^[[8~" end-of-line

# PgUp/PgDn
bindkey "^[[5"  up-line-or-history
bindkey "^[[6"  down-line-or-history

# Up/Down
# disabled in favor of zsh-history-substring-search plugin
# bindkey "\e[A" history-search-backward
# bindkey "\e[B" history-search-forward

# Ctrl + Left/Right
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word

# Ctrl+k remove to eol
bindkey "\C-k" vi-kill-eol

## Aliases
##########

alias lsl='ls -hl'
alias grep="grep --colour"

alias tmux="tmux -u2"
alias curl="curl -s"

alias vim="nvim"
alias mutt="neomutt"
alias sxivd="sxiv -r -t -s d"

alias k="kubectl"

alias xi="sudo xbps-install"
alias xr="sudo xbps-remove"
alias xq="xbps-query"

alias w="watson"

alias tlf='tmux split -h lf; lf'

## Prompt
#########

autoload -Uz vcs_info
autoload -U promptinit
promptinit

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git*' formats "%b"
precmd() {
    vcs_info
}
setopt prompt_subst
PROMPT='%F{green}#%f %F{green}%n@%m: %F{yellow}%1~%f %F{magenta}[${vcs_info_msg_0_:0:30}]%f $ '
RPROMPT='[%F{yellow}%*%f] $ '


## Plugins
##########

# https://github.com/zsh-users/zsh-history-substring-search
if [ -f ~/.zsh/zsh-history-substring-search/zsh-history-substring-search.zsh ]; then
    source ~/.zsh/zsh-history-substring-search/zsh-history-substring-search.zsh
    bindkey "\e[A" history-substring-search-up
    bindkey "\e[B" history-substring-search-down
    # bindkey '^[[A' history-substring-search-up
    # bindkey '^[[B' history-substring-search-down

    HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='fg=white,bold'
    HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='fg=red,bold'
fi

# https://github.com/zsh-users/zsh-autosuggestions
[ -f ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

# https://github.com/zsh-users/zsh-completions
[ -d ~/.zsh/zsh-completions/src ] && fpath=(~/.zsh/zsh-completions/src $fpath)

# https://github.com/direnv/direnv
# eval "$(direnv hook zsh)"

# kubectl
# eval "$(kubectl completion zsh)"
#
# krew (kubectl plugin manager)
# export PATH=$HOME/.krew/bin:$PATH


## Custom functions
###################

# tm - creates new tmux session, or switch to existing one.
tm() {
    [[ -n "$TMUX" ]] && change="switch-client" || change="attach-session"
    if [ $1 ]; then
      tmux $change -t "$1" 2>/dev/null || (tmux new-session -d -s $1 && tmux $change -t "$1"); return
    fi
    session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --exit-0) &&  tmux $change -t "$session" || echo "No sessions found."
}

# git sync
gitsync() {
    remote=${1}
    if [ -z "${remote}" ]; then
        echo "[ERROR]: remote is not specified"
        return 1
    fi
    branch=${2:-"master"}
    echo "[INFO] Sync ${remote}/${branch} to origin/${branch}"
    read -s -k "?[INFO] Press any key to continue"
    echo "\n[INFO] syncing ... "

    git fetch ${remote}
    git checkout ${branch}
    git rebase ${remote}/${branch}
    git push origin ${branch}
}

# Local zsh config
###################
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
