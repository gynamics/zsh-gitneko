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
NEKOLOR_R='%B%F{red}'
NEKOLOR_G='%B%F{green}'
NEKOLOR_B='%B%F{blue}'
NEKOLOR_C='%B%F{cyan}'
NEKOLOR_M='%B%F{magenta}'
NEKOLOR_Y='%B%F{yellow}'
NEKOLOR_W='%B%F{white}'

# get git status and save it to NEKOPS
gitneko-get() {
  local refname=$(< ${NEKOPS_HEAD}/.git/HEAD)
  if [[ $refname =~ "ref: refs/heads/.*" ]]; then
    refname=${refname#ref: refs/heads/}
  else
    refname=${refname:0:6}
  fi
  NEKOPS_BRCH="%B%F{magenta}${refname}%B%F{white}ᛘ"
  NEKOPS_ARG1="${NEKOLOR_M}?"
  NEKOPS_ARG2=""
  if [[ $(pwd) =~ "\.git" ]]; then
    return # do not run git status in .git directory
  fi
  local git_status=$(git --no-optional-locks status --porcelain=v1 .)
  if [[ $git_status =~ [ADU][ADU][\ ] ]]; then
    # Updated
    NEKOPS_ARG1="${NEKOLOR_C}·%"
  elif [[ $git_status =~ [DMTARC][\ ][\ ] ]]; then
    # Staged
    NEKOPS_ARG1="${NEKOLOR_G}6"
  elif [[ $git_status =~ [\ MTARC][\ AMTD][\ ] ]]; then
    # Unmerged
    NEKOPS_ARG1="${NEKOLOR_C}0"
  elif [[ $git_status =~ [!][!][\ ] ]]; then
    # Ignored
    NEKOPS_ARG1="${NEKOLOR_B}-"
  elif [[ $git_status =~ [X][\ ][\ ] ]]; then
    # Error
    NEKOPS_ARG1="${NEKOLOR_R}e"
  else
    # Committed
    NEKOPS_ARG1="${NEKOLOR_W}>"
  fi
  local stashcnt=$(git stash list|wc -l)
  if [ $stashcnt -gt 0 ]; then
    NEKOPS_ARG2="${NEKOLOR_Y}+"
  elif [[ $git_status =~ [\?][\?][\ ] ]]; then
    # Untracked
    NEKOPS_ARG2="${NEKOLOR_M}*"
  else
    NEKOPS_ARG2="${NEKOLOR_W}<"
  fi
}

gitneko-fresh(){
  # fresh status
  if [[ $NEKOPS_T = true ]] && [[ $NEKOPS_HEAD ]]; then
    gitneko-get
    PROMPT="%B%F{white}(%B%F{green}$(basename $NEKOPS_HEAD)${NEKOPS_PATH} %B%F{magenta}%#%b%f%k "
    if [ -n "${NEKOPS_ARG2}" ]; then
      NEKOPS="%B%F{white}(^${NEKOPS_ARG1}%B%F{white}ω${NEKOPS_ARG2}%B%F{white}^)~"
    else
      NEKOPS="%B%F{white}(^${NEKOPS_ARG1}%B%F{white}ω${NEKOPS_ARG1}%B%F{white}^)~"
    fi
    RPROMPT="%(?.%F{white} .%F{magenta}%?) ${NEKOPS_BRCH}${NEKOPS} %B%F{green}<%B%F{white}%)"
  else
    PROMPT=$NEKOPS_SAVL
    RPROMPT=$NEKOPS_SAVR
  fi
  # show python venv prompt
  if [[ $VIRTUAL_ENV_PROMPT ]] ; then
    PROMPT=$VIRTUAL_ENV_PROMPT$PROMPT
  fi
  # fresh venv save
  if [[ $VIRTUAL_ENV_PROMPT ]] ; then
    _OLD_VISUAL_PS1=$NEKOPS_SAV
  fi
}

gitneko-check() {
  local basedir=$(pwd)
  local curdir=$basedir
  # if HEAD is empty, save current prompt and start searching
  if [ -z $NEKOPS_HEAD ] ; then
    if [[ $VIRTUAL_ENV_PROMPT ]] ; then
      NEKOPS_SAV=$_OLD_VISUAL_PS1
    else
      NEKOPS_SAV=$PROMPT
    fi
  fi
  # searching up for .git/HEAD, get relative path to project rootdir
  until [ ${curdir} -ef / ] ; do
    if [ -f ${curdir}/.git/HEAD ] ; then
      # found, set it, fresh PROMPT and return here
      NEKOPS_PATH=${basedir#$curdir}
      NEKOPS_HEAD=${curdir}
      gitneko-fresh
      return
    fi
    curdir=$(dirname ${curdir})
  done
  # not found, clear all and recover
  NEKOPS_HEAD=''
  NEKOPS_PATH=''
  NEKOPS_BRCH=''
  if [[ $VIRTUAL_ENV_PROMPT ]] ; then
    PROMPT=$VIRTUAL_ENV_PROMPT$NEKOPS_SAV
  else
    PROMPT=$NEKOPS_SAV
  fi
}

gitneko-toggle(){
  if $NEKOPS_T ; then
    NEKOPS_T=false
    gitneko-get
  else
    NEKOPS_T=true
  fi
}

function gitneko(){
  case $1 in
    "-c")
      gitneko-check
      ;;
    "-f")
      gitneko-fresh
      ;;
    "-g")
      gitneko-get
      ;;
    "-h")
      echo "gitneko parameters:"
      echo "\t -c check prompt"
      echo "\t -f fresh prompt"
      echo "\t -g get git status"
      echo "\t -h show this help"
      echo "\t -t toggle prompt"
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
add-zsh-hook chpwd  gitneko-check 
add-zsh-hook precmd gitneko-fresh
gitneko-check
