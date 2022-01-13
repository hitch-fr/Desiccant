# return zero if any given string
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

# return zero if the ?given variable is
# not set, contains a null string or
# is set to the following : "null"
function is_null() {
  if [[ -z "${1+x}" ]] || [[ "${1}" == "null" ]]
  then
    return 0;
  else
    return 1;
  fi
}