# show a neko indicating repo status in git repos
# 'git status' may be slow on large projects, you can toggle it off.

# save old prompts
NEKOPS_SAVL=$PROMPT
NEKOPS_SAVR=$RPROMPT
# toggle
NEKOPS_T=true
# gitneko prompt
NEKOPS_HEAD=''
NEKOPS_PATH=''
NEKOPS_BRCH=''
NEKOPS_ARG1=""
NEKOPS_ARG2=""
NEKOPS_ARG3=""
NEKOLOR_R='%B%F{red}'
NEKOLOR_G='%B%F{green}'
NEKOLOR_B='%B%F{blue}'
NEKOLOR_C='%B%F{cyan}'
NEKOLOR_M='%B%F{magenta}'
NEKOLOR_Y='%B%F{yellow}'
NEKOLOR_W='%B%F{white}'

# get git status and save it to NEKOPS
gitneko-get-status() {
# do not run 'git status' under .git directory
if [[ $NEKOPS_PATH =~ "\.git" ]]; then
  return
fi
# reset nekops args
NEKOPS_ARG1="${NEKOLOR_M}?"
NEKOPS_ARG2=""
NEKOPS_ARG3=""
# get status and set nekops args
local git_status=$(git --no-optional-locks status --porcelain=v1 .)
# set the first argument
if [[ $git_status =~ [MTADRC][\ ][\ ] ]]; then
  # X (index) Modified
  NEKOPS_ARG1="${NEKOLOR_B}*"
elif [[ $git_status =~ [MTARC][MTD][\ ] ]]; then
  # Both XY Modified
  NEKOPS_ARG1="${NEKOLOR_G}0"
elif [[ $git_status =~ [AUD][AUD][\ ] ]]; then
  # Unmerged
  NEKOPS_ARG1="${NEKOLOR_C}6"
elif [[ $git_status =~ [X][\ ][\ ] ]]; then
  # Error
  NEKOPS_ARG1="${NEKOLOR_R}e"
else
  # Committed
  NEKOPS_ARG1="${NEKOLOR_W}>"
fi
# set the second argument
if [[ $git_status =~ [\ ][MTDRC][\ ] ]]; then
  # Y (work tree) Modified
  NEKOPS_ARG2="${NEKOLOR_Y}*"
  # if index clean, then display it to 1
  if [[ $NEKOPS_ARG1 = "${NEKOLOR_W}>" ]]; then
    NEKOPS_ARG1=$NEKOPS_ARG2
    NEKOPS_ARG2=""
  fi
fi
# these states are not that important
if [ -z $NEKOPS_ARG2 ]; then
  if [[ $git_status =~ [\?][\?][\ ] ]]; then
    # Untracked
    NEKOPS_ARG2="${NEKOLOR_B}·"
  elif [[ $git_status =~ [!][!][\ ] ]]; then
    # Ignored
    NEKOPS_ARG2="${NEKOLOR_M}-"
  elif [[ $NEKOPS_ARG1 = "${NEKOLOR_W}>" ]]; then
    # Clean
    NEKOPS_ARG2="${NEKOLOR_W}<"
  else
    NEKOPS_ARG2=$NEKOPS_ARG1
  fi
fi 
# apply status
if [ -d ${NEKOPS_HEAD}/.git/rebase-apply ]; then
  # In Rebase-Apply State
  NEKOPS_ARG3="${NEKOPS_ARG3} ${NEKOLOR_R}Ra"
fi
# stash status
local stashcnt=$(git stash list|wc -l)
if [ $stashcnt -gt 0 ]; then
  # Stashed
  NEKOPS_ARG3="${NEKOPS_ARG3} ${NEKOLOR_Y}≅ ${stashcnt}"
fi
}

gitneko-set-lprompt() {
PROMPT="${NEKOLOR_W}(${NEKOLOR_G}$(basename $NEKOPS_HEAD)${NEKOLOR_C}${NEKOPS_PATH} ${NEKOLOR_M}%#%b%f%k "
# python venv prompt support
if [ -v VIRTUAL_ENV ]; then
  PROMPT=$VIRTUAL_ENV_PROMPT$PROMPT
fi
}

gitneko-reset-lprompt() {
PROMPT=$NEKOPS_SAVL
# python venv prompt support
if [ -v VIRTUAL_ENV ]; then
  PROMPT=$VIRTUAL_ENV_PROMPT$PROMPT
fi
}

gitneko-set-rprompt() {
NEKOPS="${NEKOLOR_W}(^${NEKOPS_ARG1}${NEKOLOR_W}ω${NEKOPS_ARG2}${NEKOLOR_W}^)~${NEKOPS_ARG3}"
RPROMPT="%(?. .${NEKOLOR_R}%?) ${NEKOPS_BRCH}${NEKOPS} ${NEKOLOR_G}<${NEKOLOR_W}%)"
}

gitneko-reset-rprompt() {
RPROMPT=$NEKOPS_SAVR
}

gitneko-fresh() {
if ! $NEKOPS_T; then
  return
fi
local basedir=$(pwd)
local curdir=$basedir
# if HEAD is empty, that means prompt has not been set,
# save current prompt before start searching
if [ -z $NEKOPS_HEAD ]; then
  # python venv prompt support
  if [ -v VIRTUAL_ENV ]; then
    NEKOPS_SAVL=$_OLD_VIRTUAL_PS1
  else
    NEKOPS_SAVL=$PROMPT
  fi
  NEKOPS_SAVR=$RPROMPT
fi
# searching up for .git/HEAD, get relative path to project rootdir
until [ ${curdir} -ef / ]; do
  if [ -f ${curdir}/.git/HEAD ]; then
    # found, set it, fresh PROMPT and return here
    NEKOPS_PATH=${basedir#$curdir}
    NEKOPS_HEAD=${curdir}
    # set up branch, if ref is a hash, cut its first 7 bits.
    local refname=$(< ${NEKOPS_HEAD}/.git/HEAD)
    if [[ $refname =~ "ref: refs/heads/.*" ]]; then
      refname=${refname#ref: refs/heads/}
    else
      refname=${refname:0:6}
    fi
    # check if there is a remote branch
    if [[ -n $(git remote) ]]; then
      NEKOPS_BRCH="${NEKOLOR_B}${refname} ${NEKOLOR_C}ᛘ"
    else
      NEKOPS_BRCH="${NEKOLOR_Y}${refname} ${NEKOLOR_W}ᛘ"
    fi
    gitneko-get-status
    gitneko-set-lprompt
    gitneko-set-rprompt
    return
  fi
  curdir=$(dirname ${curdir})
done
# not found
NEKOPS_HEAD=''
NEKOPS_PATH=''
NEKOPS_BRCH=''
gitneko-reset-lprompt
gitneko-reset-rprompt
}

gitneko-toggle(){
if [ $NEKOPS_T = true ] ; then
  NEKOPS_T=false
  gitneko-fresh
else
  NEKOPS_T=true
fi
}

function gitneko(){
  case $1 in
    "-f")
      gitneko-fresh
      ;;
    "-h")
      print "Hello, I am your git neko! (^@ω@^)"
      print ""
      print -P "  eye | git status  | X (index) | Y (worktree) "
      print -P "  ----+-------------+-----------+--------------"
      print -P "  (^${NEKOLOR_C}6%b%f%kω| Unmerged    | [ADU]     | [ADU]   "
      print -P "  (^${NEKOLOR_B}*%b%f%kω| X Modified  | [MTADRC]  | [ ]     "
      print -P "  (^${NEKOLOR_G}0%b%f%kω| XY Modified | [MTARC]   | [MTD]   "
      print -P "  (^${NEKOLOR_M}-%b%f%kω| Ignored     | [!]       | [!]     "
      print -P "  (^${NEKOLOR_R}e%b%f%kω| Error       | [X]       | [ ]     "
      print -P "  (^${NEKOLOR_Y}*%b%f%kω| Y Modified  | [ ]       | [MTDRC] "
      print -P "  (^${NEKOLOR_B}·%b%f%kω| Untracked   | [?]       | [?]     "
      print -P "  (^${NEKOLOR_W}>%b%f%kω| Commited    | fallback  | fallback"
      print ""
      print -P "  toy | explanation            "
      print -P "  ----+------------------------"
      print -P "  ${NEKOLOR_R}Ra%b%f%k  | In Rebase-Apply process"
      print -P "  ${NEKOLOR_Y}≅ %b%f%k  | Stashed                "
      print ""
      print "gitneko parameters:"
      print "  -f force prompt fresh"
      print "  -h show this help"
      print "  -t toggle prompt"
      ;;
    "-t")
      gitneko-toggle
      ;;
    *)
      echo "unknown parameter, -h for help"  
      ;;
  esac
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd gitneko-fresh
gitneko-fresh
