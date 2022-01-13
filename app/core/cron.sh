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