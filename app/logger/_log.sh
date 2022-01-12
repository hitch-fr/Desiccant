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