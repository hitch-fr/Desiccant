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
# hosts has required keys

function check_hosts_requirements(){
  local conf="${1}";
  local filename=$( basename $conf );
  local hosts=$( keys $conf );

  for host in $hosts
  do
    check_host_field_nullity $host 'name' "the host $host should have the name of the computer in which you intend to execute it";

    check_host_field_nullity $host 'certificates' "the host $host should have a field 'certificates' that reference your certificates configuration files";
    
    # check_host_name $host $disabled "the host $host should have the name of the computer in which you intend to execute it";
    # check_host_certificates $host $disabled;
  done
}
# maybe check for unknown keys?

###########################
# each host configuration #
###########################

function check_host_field_nullity(){
  local host="${1}" field="${2}";

  local message="the host $host should have a field $field";
  if [[ ! -z ${3+x} ]]
  then
    message="${3}";
  fi

  local field_value=$( server $host.$field );
  if is_null $field_value
  then
    local disabled=$( server $host.disabled );
    if is $disabled
    then
      info "<% level 1 %> no $field found in $host configuration";
      info "<% level 1 %> $message";
    else
      error "no $field found in $host configuration";
      info "<% level 0 %> $message";
    fi
  fi
}

# check the email configuration if email enabled
# check the cron templates presence if cron enabled
# check the cron frequency if cron enabled

########################
# certs configurations #
########################
function check_certificate_requirement(){
  local host="${1}" cert_conf="${2}";
  local disabled=$( server $host.disabled );

}
# check config files presence
# check fqdn values
# check hooks configurations

function hosts_check(){
  local servers_conf=$( app hosts );
  servers_conf=$( path "$servers_conf" );
  info "<% level 3 %> checking hosts configuration";
  info "<% level 5 %> $servers_conf";

  conf_exists $servers_conf && \
  json_is_valid $servers_conf && \
  json_is_not_empty $servers_conf && \
  check_hosts_requirements $servers_conf && \
  return 0;
}

function config_is_valid() {
  log_header "Configuration check";
  hosts_check && \
  info "configuration ok" && \
  return 0;
}