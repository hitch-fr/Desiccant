# transfer any given local file ${2}
# to a given location ${3} on any
# given server ${1} using scp
remote_copy(){
  local server="${1}";

  local host=$( server $server.ssh.host );
  local port=$( server $server.ssh.port );
  local user=$( server $server.ssh.user );

  local action="Copying $2 to $3";
  scp -q -P $port $2 $user@$host:$3 && info "$action" || error "$action";
}