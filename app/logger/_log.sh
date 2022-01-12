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

# remove any log level tag found at the beginning
# of a message and echo this message out if its
# log level is lower than the app log config
check_log_level(){
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
    message=$( trim $message );
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