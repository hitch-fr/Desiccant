# This file is not used in the current version of desiccant
# it cames from a time Desiccant has switch from certbot to
# Dehydrated and it has been kept in case we want to give
# to Desiccant the ability to customize private keys

# As a reminder this file contain the dehydrated functions
# and the renew command that was used with those functions 
openssl_subjectaltname(){
  local fqdn_config="${1}";

  local aliases=$( domain aliases $fqdn_config );
  is_null $aliases && aliases=$( domain fqdn $fqdn_config );

  local line="";
  for alias in $aliases
  do
    line+="DNS:$alias,";
  done
  # removing the trailing comma
  echo ${line::-1};
}

generate_openssl_config(){
  local fqdn_config="${1}";

  local fqdn=$( domain fqdn $fqdn_config );

  info "Generating openssl conf" "$fqdn";

  local outputs=$( outputs $fqdn_config );
  outputs=$( path $outputs );
  local output="$outputs/$fqdn";
  
  mkdir -p "$output";

  local templates=$( app templates );
  local template=$( domain openssl.template $fqdn_config );
  template=$( path "$templates/$template" );

  if ! is_file $template
  then
    error "$fqdn : The openssl configuration $template template dont exists";
    return 1;
  else
    local conf=$( domain openssl.config $fqdn_config );
    conf="$output/$conf";

    local template_engine=$( app template_engine );
    template_engine=$( path $template_engine );

    export OPENSSL_SUBJECTALTNAME="$( openssl_subjectaltname $fqdn_config )";
    export OPENSSL_FQDN="$fqdn";

    export OPENSSL_COUNTRY_CODE=$( domain openssl.country_code $fqdn_config );
    export OPENSSL_STATE=$( domain openssl.state $fqdn_config );
    export OPENSSL_CITY=$( domain openssl.city $fqdn_config );
    export OPENSSL_ORGANISATION=$( domain openssl.organisation $fqdn_config );
    export OPENSSL_UNIT=$( domain openssl.unit_name $fqdn_config );
    export OPENSSL_EMAIL=$( domain openssl.email $fqdn_config );
    export OPENSSL_NS_COMMENT=$( domain openssl.netscape_comment $fqdn_config );

    source <($template_engine $template) > "$conf" || return 1;
  fi
  return 0;
}

generate_openssl_private_key(){
  local fqdn_config="${1}";

  local fqdn=$( domain fqdn $fqdn_config );
  info "Generating the openssl keys" "$fqdn";

  local outputs=$( outputs $fqdn_config );
  outputs=$( path $outputs );
  local output="$outputs/$fqdn";

  local privkey=$(domain openssl.private_key $fqdn_config );
  privkey="$output/$privkey";

  local conf=$( domain openssl.config $fqdn_config );
  conf="$output/$conf";

  local request=$( domain openssl.request $fqdn_config );
  request="$output/$request";

  openssl req -config "$conf" \
        -newkey rsa:4096 -sha512 -nodes \
        -outform der -out "$request" \
        -keyout "$privkey" &> /dev/null \
        || return 1;

  chmod 600 "$request" || return 1;
  return 0;
}

openssl_init(){
  local fqdn_config="${1}";

  local fqdn=$( domain fqdn $fqdn_config );

  local outputs=$( outputs $fqdn_config );
  outputs=$( path $outputs );
  local output="$outputs/$fqdn";

  local privkey=$(domain openssl.private_key $fqdn_config );
  privkey="$output/$privkey";

  if is_file "$privkey"
  then
    info "<% level 2 %> The private already exists" "$fqdn";
  else

    if generate_openssl_config $fqdn_config
    then
      info "<% level 1 %> Private successfuly created" "$fqdn";
    else
      error "Something went wrong during the openssl conf generation";
      return 1
    fi

    if generate_openssl_private_key $fqdn_config
    then
      info "<% level 1 %> Private successfuly created" "$fqdn";
    else
      error "Something went wrong during the private key generation";
      return 1
    fi
  fi

  return 0;
}

#######################
#  THE RENEW COMMAND  #
#######################

# the old renew command that create a private key with openssl
# kept for testing with a fork of dehydrated that authorize
# the use of an external private key
renew(){

  local server="${1}" fqdn_config="${2}";

  local fqdn=$( domain fqdn $fqdn_config );
  
  logger_init $fqdn;
  log_header "FQDN : $fqdn";

  info "Creating openssl files" "$fqdn";
  openssl_init $fqdn_config || return 1;

  info "<% level 1 %> Regenerating the dehydrated domains text file" "$fqdn";
  dehydrated_domain_file $fqdn_config || return 1;
  
  info "<% level 1 %> Regenerating OVH credentials file" "$fqdn";
  generate_ovh_credentials $fqdn_config || return 1;

  local outputs=$( outputs $fqdn_config );
  outputs=$( path $outputs );
  local output="$outputs/$fqdn";
  fullchain=$( path "$output/fullchain.pem" );

  if [[ -L "${fullchain}" ]] && [[ -e "${fullchain}" ]]
  then
    info "The fullchain.pem file exists, skipping the account creation" "$fqdn";
  else
    info "<% level 1 %> Creating The CA account" "$fqdn";
    dehydrated_account $fqdn_config $server || return 1;
  fi

  local renewal_rule=$( domain renewal_rule $fqdn_config );
  local rule_in_secondes=$( domain renewal_rules.$renewal_rule );
  if [[ -L "${fullchain}" ]] && [[ -e "${fullchain}" ]]
  then
    if openssl x509 -checkend "$rule_in_secondes" -noout -in $fullchain &> /dev/null
    then
      # log "$fqdn : Le certificat est toujours valide, rien à faire";
      local validity=$(openssl x509 -enddate -noout -in $fullchain);
      validity=$( echo ${validity:9} );
      validity=$( date -d "$validity" '+%m/%d/%Y' );

      local to_now=$( date +%m/%d/%Y );
      local validity_in_days=$( days_from $validity $to_now );
      info "The certificate dont expire before $validity_in_days days" "$fqdn";

      local rule_in_days=$( seconds_in_days $rule_in_secondes );
      local days_till_renewal=$(( "$validity_in_days - $rule_in_days" ));

      if (( $days_till_renewal > 1  ))
      then
        info "This certificate will not be renewed for another $days_till_renewal days" "$fqdn";
      else
        info "This certificate will be renewed soon" "$fqdn";
      fi

    else
      dehydrated_renew $fqdn_config 'renewed' || return 1;
    fi
  else
    dehydrated_renew $fqdn_config 'created' || return 1;
  fi

  return 0;
}


##############################
#  THE DEHYDRATED FUNCTIONS  #
##############################

dehydrated_account(){
  local fqdn_config="${1}";

  local fqdn=$( domain fqdn $fqdn_config );
  local conf=$( domain dehydrated.config $fqdn_config );
  conf=$( path $conf );

  local outputs=$( outputs $fqdn_config );
  outputs=$( path $outputs );

  local output="$outputs/$fqdn";

  local privkey=$( domain openssl.private_key $fqdn_config );
  privkey="$output/$privkey";

  local domains_txt=$( domain dehydrated.domains_file $fqdn_config );
  domains_txt="$output/$domains_txt";

  local ca=$( domain dehydrated.ca $fqdn_config );

  local dehydrated=$( app dehydrated );
  dehydrated=$( path "$dehydrated" );

  local logdir=$( app logger.directory );
  local logfile=$( path "$logdir/$( run_name )/$fqdn/dehydrated.txt" );
  local log_to_stdout=$( app logger.dehydrated.stdout );
  local log_to_file=$( app logger.dehydrated.file );

  # dehydrated already add /fqdn to whatever output we pass with -o
  redirect_outputs "$logfile" "$log_to_file" "$log_to_stdout" \
  $dehydrated \
      --privkey $privkey \
      --register \
      --config $conf \
      --ca $ca \
      --domains-txt $domains_txt \
      --accept-terms -o $outputs;

  if [[ $? != 0 ]]
  then
    error "Something went wrong during the CA account creation";
    return 1;
  fi

  success "CA account successfully created";
  return 0;
}

dehydrated_renew(){
  local fqdn_config="${1}" action="${2}";

  local fqdn=$( domain fqdn $fqdn_config );
  local conf=$( domain dehydrated.config $fqdn_config );
  conf=$( path $conf );

  local outputs=$( outputs $fqdn_config );
  outputs=$( path $outputs );

  local output="$outputs/$fqdn";

  local privkey=$( domain openssl.private_key $fqdn_config );
  privkey="$output/$privkey";

  local domains_txt=$( domain dehydrated.domains_file $fqdn_config );
  domains_txt="$output/$domains_txt";

  local ca=$( domain dehydrated.ca $fqdn_config );

  local hook=$( domain dehydrated.hook $fqdn_config );
  hook=$( path "$hook" );

  local credentials=$( domain ovh.output $fqdn_config );
  credentials="$output/$credentials";

  local dehydrated=$( app dehydrated );
  dehydrated=$( path "$dehydrated" );

  export OVH_HOOK_CREDENTIALS="$credentials";

  local challenge=$( domain dehydrated.challenge $fqdn_config );

  local logdir=$( app logger.directory );
  local logfile=$( path "$logdir/$( run_name )/$fqdn/dehydrated.txt" );
  local log_to_stdout=$( app logger.dehydrated.stdout );
  local log_to_file=$( app logger.dehydrated.file );

  # dehydrated already add /fqdn to whatever output we pass with -o
  redirect_outputs "$logfile" "$log_to_file" "$log_to_stdout" \
  $dehydrated \
      --privkey $privkey \
      --cron \
      --accept-terms \
      --force \
      --config $conf \
      --ca $ca \
      --domains-txt $domains_txt \
      -o $outputs \
      --challenge $challenge \
      --hook $hook;

  if [[ $? != 0 ]]
  then
    error "Something went wrong. The certificat was not $action";
    return 1;
  fi

  success "X509 certificat $action successfully";
  return 0;
}