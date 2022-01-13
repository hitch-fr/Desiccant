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

# return zero if the given variable ${1}
# contains the path of an actual file
# on the file system, else return 1
function is_file() {
  if [[ -f "${1}" ]]
  then
    return 0;
  else
    return 1;
  fi
}

# return any given string ${1}
# stripped of its leading &
# trailing whitespaces
function trim() {
  local string="${1}";
  shopt -s extglob;
  # Trim leading whitespaces
  string="${string##*( )}";
  
  # trim trailing whitespaces
  string="${string%%*( )}";

  echo "${string}";
  shopt -u extglob;
}