# return true if any given string
# ${1} is equal to true or yes
# and return false otherwise
function is() {
  if [[ "${1}" != "true" ]] && [[ "${1}" != "yes" ]]
  then
    return 1;
  else
    return 0;
  fi
}