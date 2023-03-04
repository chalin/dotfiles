#

git config --global alias.a add
git config --global alias.bD 'branch -D'
git config --global alias.c checkout
git config --global alias.cm commit
git config --global alias.b 'branch -vv'
git config --global alias.f fetch
git config --global alias.fa 'fetch --all --tags'
git config --global alias.fap 'fetch --all --tags --prune'
git config --global alias.r 'remote -v'
git config --global alias.rb rebase
git config --global alias.pl pull
git config --global alias.ps push
git config --global alias.pss 'push --set-upstream'
git config --global alias.s status
git config --global alias.sb 'status -sb'
git config --global alias.st stash
git config --global alias.pop 'stash pop'

git config --global init.defaultBranch main

alias g=git
alias gb="git branch -vv"
alias gr="git remote -v"
# alias gc="git checkout"
alias gs="git status"

if ! type __git_complete &> /dev/null; then
  BC_GIT=/usr/share/bash-completion/completions/git
  if [ -e $BC_GIT ]; then . $BC_GIT; fi
fi

if type __git_complete &> /dev/null; then
  __git_complete g __git_main
  __git_complete gb _git_branch
  __git_complete gr _git_remote
  __git_complete gc _git_checkout
  __git_complete s _git_status
fi
