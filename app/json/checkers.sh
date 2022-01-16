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
  local hosts=$( keys $conf );

  for host in $hosts
  do
    local name_is_null_msg="the value $host.name should be the name printed by the hostname command on the computer in which you intend to execute it";
    local certs_is_null_msg="the host $host should have a field 'certificates' that reference your certificates configuration files";

    check_host_field_nullity $host 'name' "$name_is_null_msg";
    check_host_field_nullity $host 'certificates' "$certs_is_null_msg";

    check_host_field_type $conf $host 'name' 'string';
    check_host_field_type $conf $host 'certificates' 'array';
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
      warning "the renewal will not run on the host $host";
      info "<% level 0 %> $message";
    fi
  fi
}

function check_host_field_type(){
  local conf="${1}" host="${2}" field="${3}" datatype="${4}";

  datatype=$( echo "${datatype}" | tr '[:upper:]' '[:lower:]' );

  local value=$( $DESICCANT_JQ ."$host.$field" $conf );
  current_type=$( printf "${value}" | $DESICCANT_JQ 'type'| tr -d '"' );
  
  if [[ $current_type != $datatype ]]
  then
    local disabled=$( server $host.disabled );
    value=$( echo $value );
    if is $disabled
    then
      info "<% level 1 %> the field $field should be of type $datatype";
      info "<% level 1 %> $host.$field: $value is currently of type $current_type";
    else
      error "bad value type of the field $field which should be of type $datatype";
      warning "the renewal will not run on the host $host";
      info "<% level 0 %> $host.$field: $value is currently of type $current_type";
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