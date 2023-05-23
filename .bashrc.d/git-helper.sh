# File git-helper.sh

# 2022-04-05: Renaming from g so as to not clash with my new g alias. I'd
# use gh, but that clashes with GitHub CLI.
function _g() {
    if [ $# -eq 0 ]; then
        echo "Error: expecting at least 1 argument"
        echo "Usage: _g cmd_abbr args..."
        return 1;
    fi

    case $1 in
        a|add)          shift; git add $*;;
        b|branch)       shift; git branch $*;;
        c|checkout)     shift; git checkout $*;;
        cb)             shift; git checkout -b $*;;
        cbr)            shift; gcbr $*;;
        # cd)             shift; git checkout --detach $*;;
        cl)             shift; git clean $*;;
        cm|commit)      shift; git commit $*;;
        df|diff)        shift; git diff $*;;
        f|fetch)        shift; git fetch $*;;
        fpr)            shift; gfpr $*;;
        fru)            shift; gfru $*;;
        frups)          shift; gfrups $*;;
        fup)            shift; git fetch upstream pull/$1/head:$1;;
        m|merge)        shift; git merge $*;;
        p)              echo "Sorry 'p' is ambiguous";;
        pl|pull)        shift; git pull $*;;
        pop)            shift; git stash pop $*;;
        ps|push)        shift; git push $*;;
        psr|psu)        shift; gpsr $*;;
        r|rem|remote)   shift; args="$*";
                        : ${args:=-vv}
                        git remote $args;;
        ra)             shift; git remote add $*;;
        rau)            shift; git remote add upstream $*;;
        re)             echo "Sorry 're' is ambiguous";;
        rb|rebase)      shift; git rebase $*;;
        rbm)            shift; git rebase master $*;;
        rbmfps)         shift; git rebase master $* && git push -f;;
        s|status)       shift; git status -sb $*;;
        st|stash)       shift; git stash $*;;
        sub)            shift;
                        : ${args:=update --init} # --remote
                        git submodule $args;;
        h|help)         myGitHelp;;
        *)              echo "Sorry I'm not sure which command you mean."
    esac
}

function myGitHelp() {
    cat <<EOF
Supported abbreviations:
  a        add
  b        branch
  c        checkout (or use gc <pattern>)
  cb       checkout -b <branch>
  cbr      <branch> [<remote>]: checkout -b <branch> <remote>/<branch>; remote defaults to upstream
  cd       checkout --detach
  cl       clean
  cm       commit
  df       diff
  f        fetch
  fu       fetch --unshallow
  fru      fetch and rebase upstream ...
  frups    fetch and rebase upstream && ps
  fup      fetch upstream pull PR#
  h        for this help
  m        merge
  pl       pull
  pop      stash pop
  ps       push
  psr      push --set-upstream <remote> (default: upstream) (was: psu)
  r.em.ote remote [--no-v]
  ra       remote add ...
  rau      remote add upstream
  rb       rebase
  rbm      rebase master
  rbmfps   rbm && ps -f
  s        status
  st       stash
  sub      submodule <cmd>; default cmd: update --init --remote

Other commands (not abbr):
  gb   git branch -v. Don't want -v, use 'g b'.
  gbd  gb -d <branch-matching-pattern-arg>
  gbD  gb -D <branch-matching-pattern-arg>
  gbp  Print the name of the branch matching the branch-pattern-arg.
  gbv  gb -vv
  gbva gb -va
  gfru git/fetch/rebase upstream (output filtered)
  gfrups git/fetch/rebase upstream (output filtered)
  glpo git log --pretty=oneline \$\*

Examples:
  git fetch -p  # prune       git log --pretty=oneline -3        git push -f
  git rebase master -i        git reset --soft HEAD~1
EOF
}

function _gb() { git branch -vv $*; }
# function gbv() { git branch -vv $*; }
# function gbva() { git branch -va $*; }
function gbg() { _gb | grep -e "${1:-gone}"; }

function gbd() {
  DEL=-d
  if [[ $1 == -D ]]; then DEL=-D; shift; fi
  if [ $# -ne 1 ]; then echo "Usage: gbd [-D] _branch_name_pattern_"; return 1; fi
  BRANCH=$(gbp "$1")
  if [ `echo "$BRANCH" | wc -l` -ne 1 ]; then echo "$BRANCH"; return 1; fi
  echo "Matched branch:"
  _gb | grep $BRANCH
  echo
  if _gb | grep $BRANCH | grep -e ' gone\b' > /dev/null; then
    echo "The branch is gone from the remote, FYI."; echo;
  fi
  echo -n "yN?Delete branch $BRANCH (y/N)? "
  read yN
  if [[ $yN == 'y' ]]; then
    echo
    git branch $DEL $BRANCH
  else
    echo "Ok, I won't delete $BRANCH."
  fi
}

function gbD() {
  if [ $# -ne 1 ]; then echo "Usage: gbD _branch_name_pattern_" return 1; fi
  gbd -D $*;
}

# Grep for choice of a branch name
function _gbc() {
  if [ $# -ne 2 ]; then
    echo "ERROR: unexpected number of arguments"
    echo "Usage: _gbc CMD pattern"
    return 1;
  fi
  CMD="$1"; shift;
  BRANCH=$($CMD | grep -v '*' | grep -e "$1")
  if [ -z "$BRANCH" ]; then
    reallyWarn;
    printf "Pattern '$1' did not match any branch (excluding current) in:\n\n"
    $CMD
    reallyWarn;
    return 1;
  fi
  if [ `echo "$BRANCH" | wc -l` -ne 1 ]; then
    reallyWarn;
    printf "\nPattern '$1' matched more than one branch:\n\n"
    printf "${BRANCH/ / }\n\n"
    reallyWarn;
    return 1;
  fi
  # Return branch name w/o leading whitespace
  echo "${BRANCH#"${BRANCH%%[![:space:]]*}"}"
}

# Get local git branch matching the given pattern. Warns if no single match found.
function gbp() { _gbc "git branch" $*; }

# Get remote git branch matching the given pattern. Warns if no single match found.
function gbr() { _gbc "git branch -r" $*; }

function gc() {
  if [[ $1 == -* || $# -ne 1 ]]; then
    echo "Unexpected arguments. Usage: gc _branch_name_pattern_"
    return 1;
  fi
  local BRANCH=$(gbp "$1")
  if [ `echo "$BRANCH" | wc -l` -ne 1 ]; then echo "$BRANCH"; return 1; fi
  git checkout $BRANCH; git branch
}

function gcbr() {
  if [[ $# -lt 1 || $# -gt 2 ]]; then echo "Usage error: gcbr [<remote>/<branch>|pattern]"; return 1; fi
  local REMOTE_BRANCH="$1"
  if [[ $REMOTE_BRANCH != */* ]]; then
    # Assume that it is a pattern
    REMOTE_BRANCH=$(gbr "$1")
    if [ `echo "$REMOTE_BRANCH" | wc -l` -ne 1 ]; then echo "$REMOTE_BRANCH"; return 1; fi
  fi
  # local remote=${2:-upstream}
  # if [[ $remote == "o" ]]; then remote=origin; fi
  CMD="git checkout -b ${REMOTE_BRANCH#*/} $REMOTE_BRANCH"
  echo $CMD
  $CMD
}

function gfru() {
  local branch=${1:-main}
  git fetch upstream && git rebase upstream/$branch && git branch -va | \
      grep -E "main|master|^remote|^From|^\*" | head
}

function checkMain() {
  local current_branch=$(git branch --show-current)
  if [[ $current_branch != "main" && $current_branch != "master" ]]; then
    echo "The current branch ($current_branch) isn't 'main' or 'master'."
    echo "This isn't usually what you want. Exiting."
    return 1;
  fi
}

function gfrups_usage() {
  echo "gfrups [-f] [-c [branch1]] [branch2]"
  echo
  echo "  Fetch upstream, rebase and push to origin; but first switch to branch1 "
  echo "  if -c flag is present. Rebasing is done from upstream/branch2, where"
  echo "  Branch2 defaults to the current branch."
  echo
  echo "  -f       Force actions even if not currently on 'main' or 'master'"
  echo "  -c [br]  First switch to given branch (default main)"
}

function gfrups() {
  # Usage:
  local current_branch=$(git branch --show-current)
  local force=
  local change=
  if [[ "$1" == "-f" ]]; then shift; force=1; fi
  if [[ "$1" == "-c" ]]; then
    shift; change=1;
    local default_branch=${1:-main}
  fi
  echo "On branch $current_branch"
  if [[ $current_branch == "main" || $current_branch == "master" || -n $force ]]; then
    true # All is good, fall through
  elif [[ -z $change ]]; then
    echo "The current branch isn't 'main' or 'master'. This isn't common."
    echo
    gfrups_usage
    return 1
  elif git diff --quiet; then
    echo "Switching to $default_branch branch"
    git switch $default_branch
    current_branch=$(git branch --show-current)
    if [[ $current_branch != $default_branch ]]; then
      echo "Oops, branch switching failed. Exiting"
      return 2
    fi
  else
    echo "Can't switch branches since there are changes. Aborting."
    return 3
  fi
  local branch=${1:-$current_branch}
  set -x
  git fetch upstream && \
    git rebase upstream/$branch && \
    git push || \
      return $?;
  _gb | grep -E "^\*"
  set +x
}

function gf() {
  local branch=${1:-main}
  if _gb | grep -qe '^\* $branch'; then
    (set -x; gfrups $*)
  else
    echo "You're not on the $branch branch. No git command executed."
  fi
}

function gfun() {
  if ! checkMain; then return 1; fi
  echo hi
  # git log -5 | grep -e ^com
}

function glpo() { git log --pretty=oneline $*; }

function gfpr() {
  local pr=$1
  local p='' # prefix

  if [[ -n $pr ]]; then
      git fetch upstream pull/$pr/head:$p$pr
  else
      echo Which PR would you like to merge?
  fi
}

function gpsr() {
  if [[ $# -gt 2 ]]; then
    echo "Usage error: gpsr [<remote> [branch]]";
    echo "  You can use 'o' as an abbreviation for 'origin'";
    return 1;
  fi
  remote=${1:-upstream}; shift;
  if [[ $remote == "o" ]]; then remote=origin; fi
  if [[ $# -eq 0 ]]; then
    branch=$(git symbolic-ref --short -q HEAD);
  else
    branch=$1; shift;
  fi
  git push --set-upstream $remote $branch $*;
}

# Sometimes, it is too easy to miss a failed command. This function
# really warns the user.
function reallyWarn() {
  echo
  echo "WARNING ** WARNING ** WARNING ** WARNING ** WARNING ** WARNING"
  echo "WARNING ** WARNING ** WARNING ** WARNING ** WARNING ** WARNING"
  echo
}
