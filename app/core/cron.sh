# return a human readable cron frequency
# string ${1} lowercased and stripped
# of extra spaces and underscores
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

# extract the minutes part of any given
# human readable cron frequency ${1}
# return 0 if this part is absent
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

# extract the hours part of any given
# human readable cron frequency ${1}
# return 0 if this part is absent
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