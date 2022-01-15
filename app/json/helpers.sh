# return the value of the given key ${1}
# from the json at the given path ${2}
function value(){
  local args="${1}" configuration_file=${2};
  # JQ returns an error when a key begin with a number unless
  # we surround it with single and double quotes '"key"'
  # but dont recognize alpha keys quoted this way
  [[ ${args::1} =~ ^[0-9]$ ]] && args=$( printf '"%s"' $args );

  local output=$($DESICCANT_JQ ."$args" $configuration_file);
  echo $output | tr -d '[],"';
}

# list the keys of the json at the given path ${1}, if
# two params are given list the #keys of the json
# object ${1} in the json at the path ${2}
function keys(){
  if [[ -z ${2+x} ]]
  then
    local configuration_file="$1";
    local args="";
  else
    local configuration_file="$2";
    local args=".$1 |";
    [[ ${args::1} =~ ^[0-9]$ ]] && args=$( printf '"%s"' $args );
  fi
  $DESICCANT_JQ "${args} keys_unsorted" $configuration_file | tr -d '[],"';
}

# return the absolute path of any given relative
# to Desiccant root path ${1} or leave any
# given absolute path ${1} unchanged
function path(){
  if [[ -z ${1+x} ]]
  then
    echo "$DESICCANT_PWD";
  else
    local path="${1}";
    [[ ${path::1} == "/" ]] && echo "$path" || echo "$DESICCANT_PWD/$path";
  fi
}

# return the value of the given ${1} option
# from the user app.json file if not null
# otherwise from the default app.json
function app(){
  local args="${1}";

  local configs="$DESICCANT_PWD/configs";
  local value="null";

  local user_config=$( path "$configs/app.json" );

  if is_file $user_config
  then
    value=$( value $args $user_config );
  fi

  if is_null $value
  then
    local defaults=$( path "$configs/defaults/app.json" );
    value=$( value $args $defaults );
  fi
  echo $value;
}

# return the value corresponding to the given
# "server.args" ${1} string from the conf
# if not found seek args in defaults
function server(){
  local arg="${1}";
  local configs=$( app configurations );
  local conf=$( app hosts );
  conf=$( path "$configs/$conf" );

  local value=$( value $arg $conf );

  if [[ $value != "null" ]]
  then
    echo $value;
  else
    conf=$( path "$configs/defaults/hosts.json" );
    # removing the server name key from $arg;
    arg=${arg#*.};
    value $arg $conf;
  fi
}

# Append the given path to the working
# directory of the given remote host
# args : hostname ${1}, path ${2}
function remote_path(){
  local server="${1}";
  local working_dir=$( server $server.working_dir );

  if [[ -z ${2+x} ]]
  then
    echo "$working_dir";
  else
    local path="${2}";
    [[ ${path::1} == "/" ]] && echo "$path" || echo "$working_dir/$path";
  fi
}

# return the value corresponding to the given
# ${1} args string from the given ${2} conf
# if not found seek args in the defaults
function domain(){
  local arg="${1}";
  local value="null";
  local configs=$( app configurations );

  if [[ ! -z ${2+x} ]]
  then
    local fqdn_config="${2}"
    local value=$( value $arg $fqdn_config );
  fi

  if [[ $value == "null" ]]
  then
    local conf=$( path "$configs/certs.json" );
    value=$( value $arg $conf );
  fi

  if [[ $value == "null" ]]
  then
    conf=$( path "$configs/defaults/certs.json" );
    local value=$( value $arg $conf );
  fi

  echo $value;
}

# return the outputs directory of the ?given
# ${1} cert config if not found try certs,
# if not found try app or app defaults
function outputs(){
  local outputs="null";

  if [[ ! -z ${1+x} ]]
  then
    local fqdn_config="${1}";
    outputs=$( domain outputs $fqdn_config );
  fi

  if [[ $outputs == "null" ]]
  then
    outputs=$( app outputs );
  fi

  if [[ $outputs == "null" ]]
  then
    outputs="certs";
  fi

  echo "$outputs";
}

# Lock the desiccant execution, when called
# this helper create a file that prevent
# any further run of the main function
lock(){
  local name="desiccant";
  [[ ! -z ${1+x} ]] && name="${1}";

  local lockfile=$( app lockfile );
  lockfile=$( path $lockfile );

  info "Locking $name";
  touch $lockfile;
}

# Remove the lockfile created by the lock
# helper, therefore authorize desiccant
# to execute its main function again
unlock(){
  local name="desiccant";
  [[ ! -z ${1+x} ]] && name="${1}";
  
  local lockfile=$( app lockfile );
  lockfile=$( path $lockfile );
  
  info "Unlocking $name";
  rm -f $lockfile;
}

# Create a run file that contain a unique
# identifier for the current run which
# is based on the time the run start
set_run(){
  local name=$( date +%d-%m-%Y_%H-%M-%S );
  local runfile=$( app runfile );
  runfile=$( path $runfile );

  info "<% level 2 %> The current run is named $name";
  touch $runfile;
  echo $name > $runfile;
}

# Retrieve the run file created by the
# set_run helper and return the run
# unique identifier stored inside
run_name(){
  local runfile=$( app runfile );
  runfile=$( path $runfile );
  
  if is_file $runfile
  then
    cat $runfile;
  fi

  return 1;
}

# Remove the run file created by the
# set_run helper and echo out the
# run unique identifier in logs
clean_run(){
  local name=$( run_name );
  local runfile=$( app runfile );
  runfile=$( path $runfile );
  info "<% level 2 %> cleaning run $name";
  rm -f $runfile;
}