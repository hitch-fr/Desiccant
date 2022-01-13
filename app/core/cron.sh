# return a human readable cron string
# ${1} lowercased and stripped of
# extra spaces and underscores
function cron_sanitize() {
  local human_freq="${1}";
  [[ ${human_freq} == '' ]] && human_freq="null";

  human_freq=$( echo "${human_freq}" | tr '[:upper:]' '[:lower:]' );
  human_freq=$( substitute "_" " " "${human_freq}" );
  human_freq=$( substitute " " "_" "${human_freq}" );
  human_freq=$( substitute '_@' '@' "${human_freq}" );
  human_freq=$( substitute '@_' '@' "${human_freq}" );
  human_freq=$( substitute '_:' ':' "${human_freq}" );
  human_freq=$( substitute ':_' ':' "${human_freq}" );

  [[ ${human_freq::6} == 'every_' ]] && human_freq=${human_freq:6};

  echo "$human_freq";
}

# extract the minutes part of the given ${1}
# human readable cron string and return it
# or return 0 if such a part dont exists
function cron_min() {
  local str="${1}";
  local min="null";
  str=$( substitute '@' '' "${str}" );

  if [[ $str =~ ^[0-9]+\:[0-9]+$ ]]
  then
    parts=($(explode ":" "${str}"));
    min="${parts[1]}";
  elif [[ $str =~ ^[0-9]+h[0-9]+$ ]]
  then
    parts=($(explode "h" "${str}"));
    min="${parts[1]}";
  fi

  if [[ $min != "null" ]]
  then
    # base10 to base10 convertion
    # auto remove heading zeros
    min=$((10#$min));
    [[ "$min" -gt "59" ]] && min=0;
  fi
  echo $min;
}

# extract the hours part of the given ${1}
# human readable cron string and return
# it, return midnight as a default
function cron_hour() {
  local str="${1}";
  local hour="null";
  str=$( substitute '@' '' "${str}" );

  if [[ $str =~ ^[0-9]+\:[0-9]+$ ]]
  then
    parts=($(explode ":" "${str}"));
    hour="${parts[0]}";
  elif [[ $str =~ ^[0-9]+h[0-9]+$ ]]
  then
    parts=($(explode "h" "${str}"));
    hour="${parts[0]}";
  elif [[ $str =~ ^[0-9]+[\:h]?$ ]]
  then
    str=$( substitute ':' '' "${str}" );
    str=$( substitute 'h' '' "${str}" );
    hour=$str;
  fi

  if [[ $hour != "null" ]]
  then
    # base10 to base10 convertion
    # auto remove heading zeros
    hour=$((10#$hour));
    [[ "$hour" -gt "23" ]] && hour=0;
  fi

  echo $hour;
}

# extract the frequency part of a given human
# readable cron string ${1} and return the
# corresponding number of days
function cron_frequency(){
  local str="${1}";
  local day="null";
  str=$( substitute '@' '' "${str}" );

  if [[ $str =~ ^everyday+s?+$ ]]
  then
    day=1;
  fi

  if [[ $str =~ ^[0-9]+$ ]]
  then
    day="$(( 10#${str} ))";
  fi

  if [[ $str =~ ^[0-9]+_day+s?+$ ]]
  then
    parts=($(explode "_" "${str}"));
    day="$(( 10#${parts[0]} ))";
  fi

  if [[ $str =~ ^week+s?+$ ]]
  then
    day=7;
  fi

  if [[ $str =~ ^[0-9]+_week+s?+$ ]]
  then
    parts=($(explode "_" "${str}"));
    day="$(( 10#${parts[0]} * 7 ))";
  fi

  if [[ $str =~ ^[0-9]+_month+s?+$ ]]
  then
    parts=($(explode "_" "${str}"));
    day="$(( 10#${parts[0]} * 30 ))";
  fi

  echo $day;
}