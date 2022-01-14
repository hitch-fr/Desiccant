# execute the common reporter
# set in the configuration
# on the given path ${1}
common_report(){
  local content_path="${1}";

  local common_reporter=$( app reporters.common );
  local enabled=$( app $common_reporter.enabled );
  
  if [[ ! -z ${2+x} ]]
  then
    local server="$2";
    local srv_enabled=$( server $server.$common_reporter.enabled )
    [[ $srv_enabled == "true" ]] || [[ $srv_enabled == "yes" ]] && enabled="true";
    [[ $srv_enabled == "false" ]] || [[ $srv_enabled == "no" ]] && enabled="false";
  fi

  if is $enabled
  then
    info "Sending $common_reporter report";
    local exec_reporter=$( app $common_reporter.script );
    exec_reporter=$( path $exec_reporter );
    $exec_reporter "$content_path";
  else
    info "${common_reporter^} reports are disabled";
  fi
}