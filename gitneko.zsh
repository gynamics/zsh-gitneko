# show a neko indicating repo status in git repos
# 'git status' may be slow on large projects, you can toggle it off.

# save old prompt
NEKOPPT_SAV=$PROMPT
# toggle
NEKOPPT_T=true
# gitneko prompt
NEKOPPT_HEAD=''
NEKOPPT_PATH=''
NEKOPPT_BRCH=''
# Unknown
NEKOPPT_UK='%B%F{white}(^?ω?^)-'
# Committed
NEKOPPT_C='%B%F{white}(^>ω<^)-'
# Untracked
NEKOPPT_U='%B%F{white}(^%B%F{cyan}·%B%F{white}ω%B%F{cyan}·%B%F{white}^)-'
# Staged(staged, modified & unmodified)
NEKOPPT_S='%B%F{white}(^%B%F{yellow}6%B%F{white}ω%B%F{yellow}6%B%F{white}^)-'
# Error
NEKOPPT_X='%B%F{white}(^%B%F{red}✦%B%F{white}ω%B%F{red}✦%B%F{white}^)-'

gitneko-get() {
  local refname=$(< ${NEKOPPT_HEAD}/.git/HEAD)
  NEKOPPT_BRCH=${refname#ref: refs/heads/}
  NEKOPPT_BRCH="%B%F{green}"$(basename $NEKOPPT_HEAD)"%B%F{white}""ᛘ""%B%F{magenta}"$NEKOPPT_BRCH
  NEKOPPT=$NEKOPPT_UK
  if $NEKOPPT_T; then
    local git_status=$(git status --porcelain=v1 -z .)
    if [[ $git_status =~ \ \?\?\  ]]; then; NEKOPPT=$NEKOPPT_U;
    elif [[ $git_status =~ \ [ACDMRTU]+\  ]];    then; NEKOPPT=$NEKOPPT_S;
    elif [[ $git_status =~ \ X\  ]];    then; NEKOPPT=$NEKOPPT_X;
    else; NEKOPPT=$NEKOPPT_C;fi
    PROMPT="%B%F{white}"${NEKOPPT_BRCH}${NEKOPPT}"%B%F{cyan}."${NEKOPPT_PATH}"%B%F{white})%B%F{blue}>%b%f%k "
  else; PROMPT=$NEKOPPT_SAV
  fi
}

gitneko-check() {
  if ! $NEKOPPT_T; then
    return
  fi
  local basedir=$(pwd)
  local curdir=$basedir
  if [ -z $NEKOPPT_HEAD ]; then
    NEKOPPT_SAV=$PROMPT
  fi
  until [ ${curdir} -ef / ]; do
    if [ -f ${curdir}/.git/HEAD ]; then
      NEKOPPT_PATH=${basedir#$curdir}
      if [[ ${curdir} == ${NEKOPPT_HEAD} ]]; then
        PROMPT="%B%F{white}"${NEKOPPT_BRCH}${NEKOPPT}"%B%F{cyan}."${NEKOPPT_PATH}"%B%F{white})%B%F{blue}>%b%f%k "
        return
      fi
      NEKOPPT_HEAD=${curdir}
      gitneko-fresh
      return
    fi
    curdir=$(dirname ${curdir})
  done
  NEKOPPT_HEAD=''
  NEKOPPT_PATH=''
  NEKOPPT_BRCH=''
  PROMPT=$NEKOPPT_SAV
}

gitneko-fresh(){
  if $NEKOPPT_T && [[ $NEKOPPT_HEAD ]] ; then
    gitneko-get
  fi
}

gitneko-toggle(){
    if $NEKOPPT_T ; then;
      NEKOPPT_T=false
      gitneko-get
    else
      NEKOPPT_T=true
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
add-zsh-hook chpwd gitneko-check 
add-zsh-hook precmd gitneko-fresh
gitneko-check
