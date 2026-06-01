# ✿ ~/.zshrc

export LANG="en_CA.UTF-8"

# ─── History ──────────────────────────────────────────────────────────────────
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS

# ─── Completion ───────────────────────────────────────────────────────────────
autoload -Uz compinit
() {
    # Anonymous function to scope EXTENDED_GLOB + LOCAL_OPTIONS
    setopt LOCAL_OPTIONS EXTENDED_GLOB
    local -a _zcd=( "${ZDOTDIR:-$HOME}"/.zcompdump(#qN.mh-24) )
    if (( ${#_zcd} )); then
        compinit -C   # dump is fresh (<24h) — skip security scan
    else
        compinit      # dump missing or stale — full rebuild
    fi
}
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors ''

# ─── Options ──────────────────────────────────────────────────────────────────
setopt AUTO_CD PROMPT_SUBST NO_BEEP

# ─── Git Prompt ───────────────────────────────────────────────────────────────
# Pastel 256-color codes (wrapped in %{%} for correct cursor width calculation)
_p_pink=$'%{\e[38;5;218m%}'    # soft pink    ✿ decoration + ⬇ behind
_p_peach=$'%{\e[38;5;216m%}'   # peach        directory path
_p_lav=$'%{\e[38;5;183m%}'     # lavender     parens, ❯ prompt char
_p_mint=$'%{\e[38;5;157m%}'    # mint         branch name, ♡ clean
_p_cream=$'%{\e[38;5;228m%}'   # soft cream   ✦ staged
_p_rose=$'%{\e[38;5;211m%}'    # rose         ✗ dirty
_p_sky=$'%{\e[38;5;153m%}'     # sky blue     ◦ untracked, ⬆ ahead
_p_rst=$'%{\e[0m%}'            # reset

_git_info() {
    (( $+commands[git] )) || return
    local branch detached=0
    branch=$(git symbolic-ref --short HEAD 2>/dev/null) \
        || { branch=$(git rev-parse --short HEAD 2>/dev/null) || return; detached=1; }

    local staged=0 dirty=0 untracked=0 line x y
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        x="${line:0:1}" y="${line:1:1}"
        if [[ "$x" == "?" && "$y" == "?" ]]; then
            (( untracked++ ))
        else
            [[ "$x" != " " ]] && (( staged++ ))
            [[ "$y" != " " ]] && (( dirty++ ))
        fi
    done < <(git status --porcelain 2>/dev/null)

    local ahead=0 behind=0 counts
    counts=$(git rev-list --count --left-right "@{upstream}...HEAD" 2>/dev/null)
    if [[ "$counts" == *$'\t'* ]]; then
        behind="${counts%%$'\t'*}"
        ahead="${counts##*$'\t'}"
        behind="${behind//[^0-9]/}"
        ahead="${ahead//[^0-9]/}"
    fi

    local label="${branch}"
    (( detached )) && label="➦ ${branch}"

    local seg="${_p_lav}(${_p_mint}${label}${_p_lav}"
    (( staged > 0 ))    && seg+=" ${_p_cream}✦${staged}"
    (( dirty > 0 ))     && seg+=" ${_p_rose}✗${dirty}"
    (( untracked > 0 )) && seg+=" ${_p_sky}◦${untracked}"
    (( ${ahead:-0} > 0 ))  && seg+=" ${_p_sky}⬆${ahead}"
    (( ${behind:-0} > 0 )) && seg+=" ${_p_pink}⬇${behind}"
    (( staged + dirty + untracked == 0 )) && seg+=" ${_p_mint}♡"
    seg+="${_p_lav})${_p_rst}"

    print -n -- "$seg"
}

_build_prompt() {
    local git_seg
    git_seg=$(_git_info)
    [[ -n "$git_seg" ]] && git_seg=" $git_seg"
    PROMPT="${_p_pink}✿${_p_rst} ${_p_peach}%~${_p_rst}${git_seg}
${_p_lav}❯${_p_rst} "
}

precmd_functions+=(_build_prompt)

# ─── Aliases ──────────────────────────────────────────────────────────────────
alias ls='ls -G'
alias ll='ls -lhG'
alias la='ls -lahG'
alias ..='cd ..'
alias ...='cd ../..'

alias g='git'
alias gs='git status'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git log --oneline --graph --decorate --all'
alias gp='git push'
alias gpl='git pull'
alias gc='git commit'
alias gcm='git commit -m'
alias gco='git checkout'
alias gb='git branch'
alias ga='git add'
alias gap='git add -p'

# ─── Path ─────────────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"
