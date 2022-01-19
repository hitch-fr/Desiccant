dehydrated_domain_file(){
  local fqdn_config="${1}";

  local fqdn=$( domain fqdn $fqdn_config );

  info "creating the Dehydrated domain text file" "$fqdn";

  local filename=$( domain dehydrated.domains_file $fqdn_config );
  local aliases=$( domain aliases $fqdn_config );
  is_null $aliases && aliases="$fqdn";

  local outputs=$( outputs $fqdn_config );
  outputs=$( path $outputs );
  
  local output="$outputs/$fqdn";

  local domains_txt="$output/$filename";

  mkdir -p "$output";

  local line="";
  for alias in $aliases
  do
    line+="$alias ";
  done

  echo "$line> $fqdn" > $domains_txt;

  if [[ $? != 0 ]]
  then
    error "Creating the Dehydrated domain file";
    return 1;
  fi

  info "<% level 2 %> Dehydrated domain file created" "$fqdn";
  return 0;
}

hooks_credentials(){
  local fqdn_config="${1}";
  local registrar=$( domain registrar $fqdn_config );
  local generate_credentials=$( domain $registrar.credentials $fqdn_config );
  
  if is_null $generate_credentials
  then
    info "<% level 1 %> no credential generation script defined for the $registrar registrar";
    return 0;
  fi

  generate_credentials=$( path "$generate_credentials" );

  if ! is_file $generate_credentials
  then
    error "credential generation script for $registrar not found";
    info "<% level 1 %> $generate_credentials no such file";
    return 1;
  fi

  if ! is_executable $generate_credentials
  then
    error "the credential generation script for $registrar is not executable";
    info "<% level 1 %> $generate_credentials is not executable";
    return 1;
  fi

  $generate_credentials $fqdn_config;
}

dehydrated_renew(){
  local fqdn_config="${1}" action="${2}";

  local fqdn=$( domain fqdn $fqdn_config );
  local conf=$( domain dehydrated.config $fqdn_config );
  conf=$( path $conf );

  local outputs=$( outputs $fqdn_config );
  outputs=$( path $outputs );

  local output="$outputs/$fqdn";

  local domains_txt=$( domain dehydrated.domains_file $fqdn_config );
  domains_txt="$output/$domains_txt";

  local ca=$( domain dehydrated.ca $fqdn_config );

  local registrar=$( domain registrar $fqdn_config );
  local hook=$( domain $registrar.hooks $fqdn_config );
  hook=$( path "$hook" );

  local credentials=$( domain $registrar.output $fqdn_config );
  if ! is_null $credentials
  then
    credentials="$output/$credentials";
    export DESICCANT_HOOK_CREDENTIALS="$credentials";
  fi

  local dehydrated=$( app dehydrated );
  dehydrated=$( path "$dehydrated" );

  local challenge=$( domain dehydrated.challenge $fqdn_config );

  local logdir=$( app logger.directory );
  local logfile=$( path "$logdir/$( run_name )/$fqdn/dehydrated.txt" );
  local log_to_stdout=$( app logger.dehydrated.stdout );
  local log_to_file=$( app logger.dehydrated.file );

  # dehydrated already add /fqdn to whatever output we pass with -o
  redirect_outputs "$logfile" "$log_to_file" "$log_to_stdout" \
  $dehydrated \
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