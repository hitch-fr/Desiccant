# return the value of the given key ${1}
# from the json at the given path ${2}
function value(){
  local args="${1}" configuration_file=${2};
  [[ ${args::1} =~ ^[0-9]$ ]] && args=$( printf '"%s"' $args );
  # args=$( printf "%s" $args );
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