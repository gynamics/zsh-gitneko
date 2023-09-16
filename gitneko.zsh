# show a neko indicating repo status in git repos
# 'git status' may be slow on large projects, you can toggle it off.

if ! [[ -x /usr/bin/git ]]; then
  echo "\e[31mgit not detected, gitneko will be disabled!\e[0m" >&2
fi

# toggle
NEKOPS_T=true
# two line mode toggle
NEKOPS_2L=false
# cascade mode toggle
NEKOPS_2C=false

# save old prompts
NEKOPS_SAVL=''
NEKOPS_SAVR=''
# gitneko prompt
NEKOPS_HEAD=''
NEKOPS_PATH=''
NEKOPS_BRCH=''
NEKOPS_ARG1=''
NEKOPS_ARG2=''
NEKOPS_ARG3=''
# zsh prompt colors
NEKOLOR_R='%B%F{red}'
NEKOLOR_G='%B%F{green}'
NEKOLOR_B='%B%F{blue}'
NEKOLOR_C='%B%F{cyan}'
NEKOLOR_M='%B%F{magenta}'
NEKOLOR_Y='%B%F{yellow}'
NEKOLOR_W='%B%F{white}'

# get git status and save it to NEKOPS
function gitneko-get-status() {
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
  NEKOPS_ARG1="${NEKOLOR_W}<"
fi
# set the second argument
if [[ $git_status =~ [\ ][MTDRC][\ ] ]]; then
  # Y (work tree) Modified
  NEKOPS_ARG2="${NEKOLOR_Y}*"
  # if index clean, then display it to 1
  if [[ $NEKOPS_ARG1 = "${NEKOLOR_W}<" ]]; then
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
  elif [[ $NEKOPS_ARG1 = "${NEKOLOR_W}<" ]]; then
    # Clean
    NEKOPS_ARG2="${NEKOLOR_W}>"
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

# reference this function from reddit channel r/zsh 
# https://www.reddit.com/r/zsh/comments/cgbm24/multiline_prompt_the_missing_ingredient/
function prompt-length() {
 emulate -L zsh
  local -i x y=${#1} m
  if (( y )); then
    while (( ${${(%):-$1%$y(l.1.0)}[-1]} )); do
      x=y
      (( y *= 2 ))
    done
    while (( y > x + 1 )); do
      (( m = x + (y - x) / 2 ))
      (( ${${(%):-$1%$m(l.x.y)}[-1]} = m ))
    done
  fi
 echo $x
}

# reference this function from reddit channel r/zsh 
# https://www.reddit.com/r/zsh/comments/cgbm24/multiline_prompt_the_missing_ingredient/
function fill-line() {
 local left_len=$(prompt-length $1)
 local right_len=$(prompt-length $2)
 local pad_len=$((COLUMNS - left_len - right_len - 1))
 local pad=${(pl.$pad_len.. .)}  # pad_len spaces
 echo ${1}${pad}${2}
}

function gitneko-set-prompt() {
# save prompts
if [[ -z $NEKOPS_SAVL ]] && [[ -z $NEKOPS_SAVR ]]; then
  NEKOPS_SAVL=$PROMPT
  # python venv prompt support
  if [ -v VIRTUAL_ENV ]; then
    NEKOPS_SAVL=$_OLD_VIRTUAL_PS1
  fi
  NEKOPS_SAVR=$RPROMPT
fi

# set prompt
if [[ -e $NEKOPS_PATH ]]; then
  local left_bottom="${NEKOLOR_M}%#%b%f%k "
  local right_bottom="%(?. .${NEKOLOR_R}%?)${NEKOPS_ARG3} "\
"${NEKOLOR_W}~(^${NEKOPS_ARG2}"\
"${NEKOLOR_W}ω${NEKOPS_ARG1}"\
"${NEKOLOR_W}^)"
  # set left prompt
  local left_top="${NEKOLOR_W}(${NEKOLOR_B}${NEKOPS_HEAD} "\
"${NEKOLOR_C}${PWD#$NEKOPS_PATH}"
  # set right prompt
  local right_top="${NEKOLOR_C}ᛘ ${NEKOPS_BRCH} "\
"${NEKOLOR_G}<${NEKOLOR_W}%)"

  if $NEKOPS_2L ; then
    PROMPT="$(fill-line ${left_top} ${right_top})"$'\n'
    RPROMPT="${right_bottom}"
  else
    PROMPT="${left_top}"
    RPROMPT="${right_bottom}${right_top}"
  fi   
  # python venv prompt support
  if [ -v VIRTUAL_ENV ]; then
    left_bottom=$VIRTUAL_ENV_PROMPT$left_bottom
  fi
  PROMPT+="${left_bottom}"
else # reset
  PROMPT=$NEKOPS_SAVL
  # python venv prompt support
  if [ -v VIRTUAL_ENV ]; then
    _OLD_VIRTUAL_PS1=$NEKOPS_SAVL
    PROMPT=$VIRTUAL_ENV_PROMPT$PROMPT
  fi
  RPROMPT=$NEKOPS_SAVR
  # clear save
  NEKOPS_SAVL=''
  NEKOPS_SAVR=''
fi
}

function gitneko-fresh() {
NEKOPS_HEAD=''
NEKOPS_PATH=''
NEKOPS_BRCH=''
if ! $NEKOPS_T; then
  # not enabled
  gitneko-set-prompt
  return
fi
if $(git rev-parse --is-inside-work-tree 2>/dev/null); then
  # inside a git worktree
  NEKOPS_PATH=$(git rev-parse --show-toplevel)
  # prefer a symbolic ref name
  NEKOPS_HEAD=$(git branch --show-current)
  if [ -z $NEKOPS_HEAD ]; then
    # try to use a commit hash
    NEKOPS_HEAD=$(git rev-parse --short HEAD 2>/dev/null)
  fi
  # is HEAD a symbolic name? (otherwise it is detached)
  if (git symbolic-ref -q HEAD >/dev/null); then
    # prefer a symbolic name
    NEKOPS_BRCH=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
    if [ -z $NEKOPS_BRCH ]; then
      # try to find a commit hash
      NEKOPS_BRCH=$(git rev-parse --short @{u} 2>/dev/null)
      if [ -z $NEKOPS_BRCH ]; then
        # no upstream found
        NEKOPS_BRCH="${NEKOLOR_R}*"
      else
        NEKOPS_BRCH="${NEKOLOR_Y}${NEKOPS_BRCH}"
      fi
    else
      NEKOPS_BRCH="${NEKOLOR_G}${NEKOPS_BRCH}"
    fi
  else
    NEKOPS_BRCH='detached' # detached
  fi
  gitneko-get-status
fi
# set up prompt
gitneko-set-prompt
}

function gitneko-erase() {
  if $NEKOPS_2C ; then
    if $NEKOPS_2L ; then
      print '\e[1A\e[K\e[1A\e[K'
    else
      print '\e[1A\e[K'
    fi
  fi
}

function gitneko() {
  case $1 in
    "-2")
      if $NEKOPS_2L; then
        NEKOPS_2L=false
      else
        NEKOPS_2L=true
      fi
      print "Two-line mode: ${NEKOPS_2L}"
      ;;
    "-c")
      if $NEKOPS_2C; then
        NEKOPS_2C=false
      else
        NEKOPS_2C=true
      fi
      print "Cascade mode: ${NEKOPS_2C}"
      ;;
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
      print "  -2 toggle 2 line mode"
      print "  -c toggle cascade mode"
      ;;
    "-t")
      NEKOPS_T=!$NEKOPS_T
      gitneko-fresh
      ;;
    *)
      echo "unknown parameter, -h for help"  
      ;;
  esac
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd gitneko-fresh
add-zsh-hook preexec gitneko-erase
gitneko-fresh
