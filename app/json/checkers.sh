function conf_exists(){
  local conf="${1}";
  local filename=$( basename $conf );

  if is_file $conf
  then
    info "<% level 1 %> the $filename configuration file exists";
    return 0;
  else
    error "the $filename configuration file was not found";
    info "<% level 1 %> file path : $conf";
    return 1;
  fi
}

function json_is_valid(){
  local conf="${1}";
  local filename=$( basename $conf );

  if $DESICCANT_JQ 'keys' $conf &> /dev/null
  then
    info "<% level 2 %> the file $filename is a valid json";
    return 0;
  else
    error "the file $filename is not a valid json";
    info "<% level 1 %> file path : $conf";
    return 1;
  fi
}

function json_is_not_empty(){
  local conf="${1}";
  local filename=$( basename $conf );

  local keys=$( keys $conf );
  if [[ $keys != "" ]]
  then
    info "<% level 3 %> the file $filename is not empty";
    return 0;
  else
    error "$filename should not be empty";
    info "<% level 2 %> file path : $conf";
    return 1;
  fi
}

##############
# app checks #
##############

# JQ is_file and is executable
# bash-tpl is present and executable
# dehydrated is persent and executable

#######################
# hosts configuration #
#######################

# ✓ check hosts.json presence
# ✓ jq can read the file
# ✓ hosts conf have at least one host

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
  log_header "Configuration check";
  local servers_conf=$( app hosts );
  servers_conf=$( path "$servers_conf" );
  info "<% level 3 %> checking hosts configuration";
  info "<% level 5 %> $servers_conf";

  conf_exists $servers_conf && \
  json_is_valid $servers_conf && \
  json_is_not_empty $servers_conf && \
  info "configuration ok" && \
  return 0;
}