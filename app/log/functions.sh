# initialize the logger by creating the log
# dir and the current run log dir and add
# a subdir if any ${1} subdir is given
logger_init(){
  local filename="report.txt";
  local logdir=$( app logger.directory );

  local current_run=$( run_name );

  logdir+="/$current_run";
  if [[ ! -z ${1+x} ]]
  then
    logdir+="/${1}";
  fi

  logdir=$( path $logdir );

  mkdir -p $logdir;

  local logfile=$( path $logdir/$filename );
  touch $logfile;
}

logger_clean(){
  local keep="$( app logger.keep )";
  local logdir=$( app logger.directory );
  info "<% level 0 %> $logdir directory cleaning";
  logdir=$( path $logdir );

  local runs=$( ls -t $logdir );
  local i=1;
  for dirname in $runs
  do

    if [[ ! -d "$logdir/$dirname" ]]
    then
      continue;
    fi

    local run=($( explode "_" $dirname ));

    if [[ -z ${run[1]+x} ]]
    then
      continue;
    fi

    local date="${run[0]}";
    local time="${run[1]}";
    time=$( substitute "-" ":" $time );
    date=($( explode "-" $date ));

    if [[ -z ${date[1]+x} ]]
    then
      continue;
    fi

    date=$( human_date "${date[2]}/${date[1]}/${date[0]} $time" );

    if [[ -z $date ]]
    then
      continue;
    fi

    if [[ $i -eq $keep ]]
    then
      info "<% level 1 %> all log file older than $date will be removed";
    fi

    if [[ $i -gt $keep ]]
    then
      info "<% level 2 %> removing logs of the $date";
      rm -rf "$logdir/$dirname";
    fi
    ((++i))
  done
}

# remove any log level tag found at the beginning
# of a message and echo this message out if its
# log level is lower than the app log config
log_level_filter(){
  local message="${@}";
  local msg_lvl=0;
  local app_lvl=$( app logger.level );

  if [[ "${message}" == "<%"*"%>"* ]]
  then
    msg_lvl=${message%\%\>*}
    msg_lvl=${msg_lvl#\<\%*level*}
    msg_lvl=$( trim $msg_lvl );
    [[ $msg_lvl =~ ^[0-9]+$ ]] || msg_lvl=0; 

    message=${message#\<\%*\%\>};
    message=$( trim "$message" );
  fi

  if (( $msg_lvl <= $app_lvl ))
  then
    echo "$message";
  fi
}

# prepend the system time to any given ${1}
# message and print the resulting string
# to the standard output if app stdout
console_log(){
  local message="${1}";

  local stdout_on=$( app logger.stdout );
  if is $stdout_on
  then
    local now="$(date '+%H:%M')";
    printf "$now $message\n";
  fi
}

# prepend the system time to any given ${1}
# message and print it to logfile in the
# logdir or in the ?given ${2} subdir
files_log(){
  local message="${1}";

  local logfile_on=$( app logger.file );

  if is $logfile_on
  then
    local filename="report.txt";

    local logdir=$( app logger.directory );
    local current_run=$( run_name );
    logdir+="/$current_run";
    logdir=$( path $logdir );
    local path=$( path "$logdir/$filename" );

    local now="$(date '+%H:%M')";
    message="$now $message";

    printf "$message\n" >> $path;

    if [[ ! -z "${2+x}" ]]
    then
      path=$( path "$logdir/$2/$filename" );
      printf "$message\n" >> $path;
    fi
  fi
}

# print out any given ${1} message to both
# logdir/logfile and the standard output
# regardless of the app logger config
log_header(){
  local title="${@}";

  local filename="report.txt";

  local logdir=$( app logger.directory );
  local current_run=$( run_name );
  logdir+="/$current_run";
  logdir=$( path $logdir );
  tmp="$logdir/$filename";

  local title_line="";
  local half="‾‾‾‾";
  local spaces="    ";
  local len=${#1};

  for (( i=0; i<$len; i++ ));
  do
    title_line+="‾";
  done
  local t;
  t="\n";
  t+="${half}${title_line}${half}\n";
  t+="${spaces}${title}\n";
  t+="${half}${title_line}${half}\n";
  t+="\n";

  printf "$t";
  printf "$t" >> $tmp;

}

# set the $TERM environment variable if
# dont exists and print the color as
# the ?given ${1} tput setaf color
log_color(){
  [[ -z ${TERM+x} ]] && local TERM="xterm-256color";
  local color=0;
  [[ ! -z ${1+x} ]] && color="${1}";
  echo `tput -T $TERM setaf "${color}"`;
}

# set the $TERM environment variable if
# dont exists and echo the tput sgr0
# command output that reset colors
log_reset_color(){
  [[ -z ${TERM+x} ]] && local TERM="xterm-256color";
  echo `tput -T $TERM sgr0`;
}

# filter any given $1 log message by level
# prepend the INFO mension and color it
# for console_log and files_log calls
info(){
  local msg=$( log_level_filter "$1" );
  msg="${msg^}";
  local fqdn="";
  if [[ ! -z "${2+x}" ]]
  then
    fqdn="${2}";
  fi

  if ! is_null $msg;
  then
    local blue=$( log_color 6 );
    local reset=$( log_reset_color );
    console_log "${blue}INFO :${reset} $msg";
    files_log "INFO : $msg" $fqdn;
  fi
}

# prepend to any given ${1} message
# the SUCCESS mension add colors
# and pass it to log functions
success(){
  local msg=$( trim "$@" );
  msg="${msg^}";

  local green=$( log_color 2 );
  local reset=$( log_reset_color );
  console_log "${green}SUCCESS :${reset} $msg";
  files_log "SUCCESS : $msg";
}

# prepend to any given ${1} message
# the WARNING mension add colors
# and pass it to log functions
warning(){
  local msg=$( trim "$@" );
  msg="${msg^}";

  local orange=$( log_color 3 );
  local reset=$( log_reset_color );
  console_log "${orange}WARNING :${reset} $msg";
  files_log "WARNING : $msg";
}

# prepend to any given ${1} message
# the DANGER mension add the red
# color and call log functions
danger(){
  local msg=$( trim "$@" );
  msg="${msg^}";

  local red=$( log_color 1 );
  local reset=$( log_reset_color );
  console_log "${red}DANGER :${reset} $msg";
  files_log "DANGER : $msg";
}

# prepend a given ${1} message
# the red colored ERROR tag
# and pass it for logging
error(){
  local msg=$( trim "$@" );
  msg="${msg^}";

  local red=$( log_color 1 );
  local reset=$( log_reset_color );
  console_log "${red}ERROR :${reset} $msg";
  files_log "ERROR : $msg";
}