##############
# app checks #
##############

# JQ is_file and is executable
# bash-tpl is present and executable
# dehydrated is persent and executable

#######################
# hosts configuration #
#######################

# check hosts.json presence
function conf_exists(){
  local conf="${1}";

  info "<% level 4 %> checking existence of $conf";
  if is_file $conf
  then
    info "<% level 3 %> the configuration file exists";
    return 0;
  else
    error "the configuration file was not found";
    return 1;
  fi
}

# jq can read the file
function json_is_valid(){
  local conf="${1}";

  info "<% level 4 %> checking json $conf";

  if $DESICCANT_JQ 'keys' $conf &> /dev/null
  then
    info "<% level 3 %> the json file is valid";
    return 0;
  else
    error "invalid json file";
    return 1;
  fi
}
# hosts conf have at least one host
# maybe check for unknown keys?

###########################
# each host configuration #
###########################

# check the email configuration if email enabled
# check the cron templates presence if cron enabled
# check the cron frequency if cron enabled

########################
# certs configurations #
########################

# check config files presence
# check fqdn values
# check hooks configurations

function config_is_valid() {
  local servers_conf=$( app hosts );
  servers_conf=$( path "$servers_conf" );

  conf_exists $servers_conf && \
  json_is_valid $servers_conf && \
  info "configuration ok" && \
  return 0;
}