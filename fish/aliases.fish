# Aliases — fish port of zsh/aliases.zsh.
#
# Sourced from config.fish *after* cachyos-config.fish, so where the two
# overlap (ls, lt) these definitions win. CachyOS's own extras (.., update,
# mirror, cleanup, jctl, rip, la, ll, l.) are left in place.

# ALIASES ---------------------------------------------------------------------
alias d 'docker'
alias dc 'docker-compose'

alias v 'nvim'
alias vi 'nvim'
alias vim 'nvim'

alias l 'eza -lah --group-directories-first --git --icons=auto'
alias ls 'eza --icons=auto'
alias lst 'eza --tree --level=2 --group-directories-first --git --icons=auto'

alias c 'clear'
alias s 'source $__fish_config_dir/config.fish'

# OH MY PI --------------------------------------------------------------------
# Lean orchestrator: main agent gets only read/write/bash/task and delegates
# everything else to subagents (see ~/.omp/agent/agents/*.md).
alias ompl 'omp --tools read,write,bash,task'

# GIT ALIASES -----------------------------------------------------------------
alias gc 'git commit'
alias gco 'git checkout'
alias ga 'git add'
alias gb 'git branch'
alias gba 'git branch --all'
alias gbd 'git branch -D'
alias gcp 'git cherry-pick'
alias gd 'git diff -w'
alias gds 'git diff -w --staged'
alias grs 'git restore --staged'
alias gu 'git reset --soft HEAD~1'
alias gpr 'git remote prune origin'
alias ff 'gpr && git pull --ff-only'
alias grd 'git fetch origin && git rebase origin/master'
alias gbf 'git branch | head -1 | xargs' # top branch
alias grc 'git rebase --continue'
alias gra 'git rebase --abort'
alias gcan 'gc --amend --no-edit'

alias gp 'git push'
alias gpf 'git push --force-with-lease'

alias gg 'git branch | fzf | xargs git checkout'

# FUNCTIONS -------------------------------------------------------------------
# These were single-quoted zsh aliases upstream; command substitution and `$*`
# don't survive the translation, so they become functions here.

function git-current-branch --description 'Name of the checked-out branch'
    git branch | grep \* | cut -d ' ' -f2
end

function gst --description 'git status, or a directory listing outside a repo'
    if git rev-parse --git-dir >/dev/null 2>&1
        git status
    else
        eza
    end
end

function gup --description 'Track origin/<current branch>'
    set -l branch (git-current-branch)
    git branch --set-upstream-to=origin/$branch $branch
end

function gl --description 'One-line graph log'
    git log --graph \
        --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' \
        --abbrev-commit $argv
end

function gla --description 'Alias of gl'
    gl $argv
end
