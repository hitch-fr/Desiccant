# get the cron configuration of the given ${1} server
# create temporary cron file accordingly and copy
# it to the cron.d directory in the local server
enable_local_cron(){
  local server="${1}";

  local frequency=($( get_cron $server ));

  local day=${frequency[0]};
  local hour=${frequency[1]};
  local min=${frequency[2]};
  local warn="${frequency[3]}";

  if [[ $warn != "null" ]]
  then
    warning "$server : $warn";
  fi

  local templates=$( app templates );
  local template=$( server $server.cron.template );
  template=$( path "$templates/$template" );

  if is_file $template
  then
    local cron_command=$( server $server.cron.script );

    export CRON_USER=$( server $server.cron.user );
    export CRON_COMMAND=$( path $server "$cron_command" );
    export CRON_FREQUENCY=$( echo "$min" "$hour" "$day" '*' '*' | tr -d "'");

    local template_engine=$( app template_engine );
    template_engine=$( path $template_engine );

    local tempfile="/tmp/desiccant_cron_tmp";
    local cronfile=$(server $server.cron.filename);
    source <($template_engine $template) > "/etc/cron.d/$cronfile";

  else
    error "$server : the cron template file does not exists";
  fi
}

# remove the main desiccant cron
# file from the given ${1}
# server file system
disable_local_cron(){
  local server="${1}";
  local crondir="/etc/cron.d";
  local filename=$( server $server.cron.filename );

  rm -f "$crondir/$filename";
}

# create or remove the cron file of
# the given ${1} server according
# to its cron.enabled option
local_cronfile(){
  local server="${1}";

  local cron_enabled=$( server $server.cron.enabled );
  if is $cron_enabled
  then
    enable_local_cron $server;
  else
    disable_local_cron $server;
  fi
}