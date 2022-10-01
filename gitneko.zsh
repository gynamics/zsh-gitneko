# show a neko indicating repo status in git repos
# 'git status' may be slow on large projects, you can toggle it off.

# save old prompt
NEKOPS_SAV=$PROMPT
# toggle
NEKOPS_T=true
# gitneko prompt
NEKOPS_HEAD=''
NEKOPS_PATH=''
NEKOPS_BRCH=''
# Unknown
NEKOPS_UK='%B%F{white}(^?ω?^)-'
# Committed
NEKOPS_C='%B%F{white}(^>ω<^)-'
# Untracked
NEKOPS_U='%B%F{white}(^%B%F{cyan}·%B%F{white}ω%B%F{cyan}·%B%F{white}^)-'
# Staged(staged, modified & unmodified)
NEKOPS_S='%B%F{white}(^%B%F{yellow}6%B%F{white}ω%B%F{yellow}6%B%F{white}^)-'
# Error
NEKOPS_X='%B%F{white}(^%B%F{red}✦%B%F{white}ω%B%F{red}✦%B%F{white}^)-'

# get git status and save it to NEKOPS
gitneko-get() {
  local refname=$(< ${NEKOPS_HEAD}/.git/HEAD)
  NEKOPS_BRCH=${refname#ref: refs/heads/}
  NEKOPS_BRCH="%B%F{green}$(basename $NEKOPS_HEAD)%B%F{white}ᛘ%B%F{magenta}${NEKOPS_BRCH}"
  NEKOPS=$NEKOPS_UK
  if $NEKOPS_T; then
    local git_status=$(git status --porcelain=v1 -z .)
    if [[ $NEKOPS_T ]]; then
      local git_status=$(git status --porcelain=v1 -z .)
      if [[ $git_status =~ \ \?\?\ .* ]]; then
        NEKOPS=$NEKOPS_U
      elif [[ $git_status =~ [\ ]*[ACDMRTU]+[\ ]*\ .* ]]; then
        NEKOPS=$NEKOPS_S
      elif [[ $git_status =~ [\ ]*[X][\ ]*\ .* ]]; then
        NEKOPS=$NEKOPS_X
      else
        NEKOPS=$NEKOPS_C
      fi
    fi
  fi
}

gitneko-fresh(){
  # fresh status
  if $NEKOPS_T && [[ $NEKOPS_HEAD ]] ; then
    PROMPT="%B%F{white}${NEKOPS_BRCH}${NEKOPS}%B%F{cyan}.${NEKOPS_PATH}%B%F{white})%B%F{blue}>%b%f%k "
    gitneko-get
  else
    PROMPT=$NEKOPS_SAV
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
