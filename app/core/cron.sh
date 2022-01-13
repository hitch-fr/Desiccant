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

# take the given ${1} human readable cron string
# and make an array that contain the frequency
# (in days) and the execution time (hour min)
function cron_translate(){
  local human_freq="${1}";
  local day="null" hour="null" min="null";

  if [[ $human_freq =~ ^[0-9]+\:[0-9]+$ ]] || [[ $human_freq == "@"* ]]
  then
    # only time string hh:mm, @hh:mm or @hh
    hour=$( cron_hour "${human_freq}" );
    min=$( cron_min "${human_freq}" );

  elif [[ $human_freq =~ ^[^@]+$ ]] || [[ $human_freq == *"@" ]]
  then
    # only days
    day=$( cron_frequency "${human_freq}" );

  elif [[ $human_freq == *"@"* ]]
  then
    local parts=($(explode "@" "${human_freq}"));
    day_part=${parts[0]};
    time_part=${parts[1]};

    day=$( cron_frequency "${day_part}" );
    hour=$( cron_hour "${time_part}" );
    min=$( cron_min "${time_part}" );
  fi

  local cron_freq=();
  cron_freq[0]=$day;
  cron_freq[1]=$hour;
  cron_freq[2]=$min;

  echo "${cron_freq[@]}";
}

# take the human readable cron string from the given ${1} server's
# configuration, fill the possible blanks with the string in the
# app defaults and return a well formatted cron frequency line
function get_cron(){
  local server="${1}";
  local day hour min parts;
  local message="null";

  local human_freq=$( server $server.cron.frequency );
  local human_freq=$( cron_sanitize "${human_freq}" );

  if [[ $human_freq =~ ^[0-9]+?_?minutes?$ ]] || [[ $human_freq =~ ^[0-9]+?_?mins?$ ]]
  then
    parts=($(explode "_" "${human_freq}"));
    [[ -z "${parts[1]+x}" ]] && min=1 || min=${parts[0]};
    min="'*'/$(( 10#${min} ))";
    hour="'*'";
    day="'*'";
  elif [[ $human_freq =~ ^[0-9]+?_?hour+s?$ ]]
  then
    parts=($(explode "_" "${human_freq}"));
    [[ -z "${parts[1]+x}" ]] && hour=1 || hour=${parts[0]};
    min=0;
    hour="'*'/$(( 10#${hour} ))";
    day="'*'";
  else
    local cron_freq=($( cron_translate $human_freq ));

    day=${cron_freq[0]};
    hour=${cron_freq[1]};
    min=${cron_freq[2]};

    [[ $day != "null" ]] && day="'*'/$(( 10#${day} ))";
  fi

  if [[ $day == "null" ]] || [[ $hour == "null" ]] || [[ $min == "null" ]]
  then
    local default_freq=$( value cron.frequency $DESICCANT_PWD/configs/defaults/hosts.json );

    local bad_settings="false";

    [[ $human_freq == *"@"* ]] ||\
    [[ $human_freq =~ ^[^@]+$ ]] ||\
    [[ $human_freq == *"@" ]] &&\
    [[ $day == "null" ]] && bad_settings="true";

    if [[ $bad_settings == "true" ]]
    then
      human_freq=($(explode "@" "${human_freq}"));
      local default_d=($(explode "@" "${default_freq}"));
      message="Unknown cron frequency ${human_freq[0]}, set to default (${default_d[0]})";
    fi

    default_freq=$( cron_sanitize "${default_freq}" );
    local cron_freq=($( cron_translate $default_freq ));

    [[ $day == "null" ]] && day="'*'/$(( 10#${cron_freq[0]} ))";
    [[ $hour == "null" ]] && hour=${cron_freq[1]};
    [[ $min == "null" ]] && min=${cron_freq[2]};
  fi

  local cron_freq=();
  cron_freq[0]=${day};
  cron_freq[1]=${hour};
  cron_freq[2]=${min};
  cron_freq[3]="${message}";

  echo "${cron_freq[@]}";
}