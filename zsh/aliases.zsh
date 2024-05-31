# ALIASES ---------------------------------------------------------------------
alias d=docker
alias dc=docker-compose

alias v='nvim'
alias vi='nvim'
alias vim='nvim'

alias l='eza -lah --group-directories-first --git --icons'
alias ls='eza --icons'
alias lst='eza --tree --level=2 --group-directories-first --git --icons'

alias c='clear'
alias s='source ~/.zshrc'

# GIT ALIASES -----------------------------------------------------------------
alias gc='git commit'
alias gco='git checkout'
alias ga='git add'
alias gb='git branch'
alias gba='git branch --all'
alias gbd='git branch -D'
alias gcp='git cherry-pick'
alias gd='git diff -w'
alias gds='git diff -w --staged'
alias grs='git restore --staged'
alias gst='git rev-parse --git-dir > /dev/null 2>&1 && git status || exa'
alias gu='git reset --soft HEAD~1'
alias gpr='git remote prune origin'
alias ff='gpr && git pull --ff-only'
alias grd='git fetch origin && git rebase origin/master'
alias gbf='git branch | head -1 | xargs' # top branch
alias gl="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias gla=gl
alias git-current-branch="git branch | grep \* | cut -d ' ' -f2"
alias grc='git rebase --continue'
alias gra='git rebase --abort'
alias gcan='gc --amend --no-edit'

alias gp="git push"
alias gpf='git push --force-with-lease'

alias gg='git branch | fzf | xargs git checkout'
alias gup='git branch --set-upstream-to=origin/$(git-current-branch) $(git-current-branch)'

# FUNCTIONS -------------------------------------------------------------------
