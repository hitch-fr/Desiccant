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

function remote_path(){
  local working_dir=$( server $server.working_dir );

  if [[ -z ${1+x} ]]
  then
    echo "$working_dir";
  else
    local path="${1}";
    [[ ${path::1} == "/" ]] && echo "$path" || echo "$working_dir/$path";
  fi
}