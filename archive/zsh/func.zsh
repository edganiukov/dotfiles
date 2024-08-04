# nnn
n() {
    # Block nesting of nnn in subshells
    if [ -n $NNNLVL ] && [ "${NNNLVL:-0}" -ge 1 ]; then
        echo "nnn is already running"
        return
    fi

    # Unmask ^Q (if required, see `stty -a`) to Quit nnn
    stty start undef
    stty stop undef
    stty lnext undef

    NNN_CTXMAX=1 \
    NNN_BMS="h:~;t:~/tmp" \
    NNN_TRASH=1 \
    NNN_PLUG="d:diffs;m:nmount;n:notes;v:imgview" \
    NNN_USE_EDITOR=1 \
    NNN_COLORS="4444" \
    NNN_COPIER="xargs -0 < \"$SELECTION\" | xclip -selection clipboard -i" \
    NNN_FIFO="/tmp/nnn.fifo" \
    nnn -e -x -o -C "$@"
}

# tm - creates new tmux session, or switch to existing one.
tm() {
    [[ -n "$TMUX" ]] && change="switch-client" || change="attach-session"
    if [ $1 ]; then
      tmux $change -t "$1" 2>/dev/null || (tmux new-session -d -s $1 && tmux $change -t "$1"); return
    fi
    session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --exit-0) &&  tmux $change -t "$session" || echo "No sessions found."
}

gitsync() {
    local remote=${1:-"upstream"}
    local branch=${2:-"master"}
    echo "[INFO] Sync ${remote}/${branch} to origin/${branch}"
    read -s -k "?[INFO] Press any key to continue"
    echo "\n[INFO] syncing ... "

    local cbranch=$(git branch --show-current)

    git checkout ${branch}
    git fetch ${remote}
    git rebase ${remote}/${branch}
    git push origin ${branch}

    git checkout ${cbranch}
}

fbr() {
    local action=${1:-"co"}
    case $action in
    "del")
        git branch --no-color --sort=-committerdate --format='%(refname:short)' |
            fzf --header "git branch -D" --multi --ansi --tabstop=4 --preview-window 'right:60%' --preview="git lg {} --" |
            xargs --no-run-if-empty git branch --delete --force
        ;;
    "co")
        git branch --no-color --sort=-committerdate --format='%(refname:short)' |
            fzf --header "git checkout" --ansi --tabstop=4 --preview-window 'right:60%' --preview="git lg {} --" |
            xargs --no-run-if-empty git checkout
        ;;
    esac
}

fpr() {
    local lim=${1:-"30"}
    gh pr list -L $lim | fzf --header "gh pr checkout" --tabstop=4 |
        awk '{print $1}' | xargs --no-run-if-empty gh pr checkout
}
