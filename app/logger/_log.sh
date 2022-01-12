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