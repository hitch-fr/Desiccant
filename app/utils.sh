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

# return the given string ${3} with every
# occurence of the searched string ${1}
# replaced by the replace string ${2}
function substitute() {
  local SEARCH="${1}" REPLACE="${2}" STRING="${3}";
  echo ${STRING//$SEARCH/$REPLACE};
}

# call: array=("$(explode $delimiter $string)")
# return an array in which each element
# is a part of the given string ${2}
# splitted by the ${1} delimiter
function explode() {
    local delimiter="${1}" string="${2}"
    local IFS="${delimiter}"; shift; read -a array <<< "${string}";
    if [[ "${array[@]}" ]]; then echo "${array[@]}"; else return 1; f
    unset IFS delimiter string
}

# return the english formatted
# string that represent the
# execution date and time
function now(){
  LC_ALL=en_UK.utf8 date '+on %A, %B %d, %Y at %H:%M';
}

# return a string that represent
# the execution year
function year(){
  date '+%Y';
}

# take a given number of days ${1}
# and return the corresponding
# number of seconds
function days_in_seconds(){
  echo $(( "$1" * 86400 ));
}

# return the corresponding number
# of days from the given number
# of seconds ${1}
function seconds_in_days(){
  echo $(( "$1" / 86400 ));
}

# return the number of days
# between the given dates
# strings ${1} and ${2}
function days_from(){
  local date_1=$( date -d "$1" '+%s' );
  local date_2=$( date -d "$2" '+%s' );
  seconds_in_days "$(( $date_1 - $date_2 ))";
}