# get the cron configuration of the given ${1} server's
# create temporary cron file accordingly and send it
# to the remote server with remote_copy function
enable_remote_cron(){
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

  local user=$( server $server.ssh.user );

  local templates=$( app templates );
  local template=$( server $server.cron.template );
  template=$( path "$templates/$template" );

  if is_file $template
  then
    local cron_command=$( server $server.cron.script );

    export CRON_USER=$( server $server.cron.user );
    export CRON_COMMAND=$( remote_path $server "$cron_command" );
    export CRON_FREQUENCY=$( echo "$min" "$hour" "$day" '*' '*' | tr -d "'");

    local template_engine=$( app template_engine );
    template_engine=$( path $template_engine );

    # local content=$(source <($template_engine $template));

    local tempfile="/tmp/desiccant_cron_tmp";
    source <($template_engine $template) > "$tempfile";

    local remote_cronfile=$(server $server.cron.filename);
    remote_cronfile="/etc/cron.d/$remote_cronfile";
    remote_copy $server $tempfile $remote_cronfile;
    rm $tempfile;
  else
    error "$server : the cron template file does not exists";
  fi
}