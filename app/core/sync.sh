sync(){
  local server="${1}";

  local host=$( server $server.ssh.host );
  local port=$( server $server.ssh.port );
  local user=$( server $server.ssh.user );
  local working_dir=$( server $server.working_dir );

  local lockfile=$( app lockfile );
  local logdir=$( app logger.directory );
  local outputs=$( outputs );
  local runfile=$( app runfile );

  info "$host : Synchronizing $DESICCANT_PWD with $working_dir";
  rsync --delete -az $DESICCANT_PWD/ -e "ssh -T -p $port" $user@$host:$working_dir/ \
  --exclude "$lockfile" \
  --exclude "$runfile" \
  --exclude "/$logdir" \
  --exclude "/$outputs" \
  --exclude '.git' \
  --exclude '.gitignore' \
  --exclude '.gitmodules' \
  --exclude '.vscode';
}

remote_renew(){
  local server="${1}";
  local renewable=$( server $server.renew_on_sync );
  if is $renewable
  then
    local working_dir=$( server $server.working_dir );
    local cmd=$( server $server.cron.script );
    remote_command $server "$working_dir/$cmd";
  fi
}

remove_all_desiccant_cronfiles(){
  local server="${1}";

  local host=$( server $server.ssh.host );
  local port=$( server $server.ssh.port );
  local user=$( server $server.ssh.user );

  local remove=$(server $server.cron.remove_all);
  if [[ $remove == "true" ]] || [[ $remove == "yes" ]]
  then
    local crondir="/etc/cron.d";
    local list=$( ssh -p $port $user@$host "ls $crondir");
    local prefix=$(server $server.cron.prefix);
    for file in $list
    do
      [[ $file == $prefix-* ]] && remote_command $server "rm $crondir/$file"; 
    done
  fi
}