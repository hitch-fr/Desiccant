# return the value of the given key ${1}
# from the json at the given path ${2}
function value(){
  local args="${1}" configuration_file=${2};
  [[ ${args::1} =~ ^[0-9]$ ]] && args=$( printf '"%s"' $args );
  # args=$( printf "%s" $args );
  local output=$($DESICCANT_JQ ."$args" $configuration_file);
  echo $output | tr -d '[],"';
}