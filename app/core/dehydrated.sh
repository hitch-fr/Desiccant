dehydrated_domain_file(){
  local fqdn_config="${1}";

  local fqdn=$( domain fqdn $fqdn_config );
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

generate_ovh_credentials(){
  local fqdn_config="${1}";
  
  local fqdn=$( domain fqdn $fqdn_config );

  local credentials_filename=$( domain ovh.output $fqdn_config );

  local outputs=$( outputs $fqdn_config );
  outputs=$( path $outputs );
  
  local output="$outputs/$fqdn";
  
  local credentials="$output/$credentials_filename";

  export OVH_ENDPOINT=$( domain ovh.endpoint $fqdn_config );
  export OVH_KEY=$( domain ovh.key $fqdn_config );
  export OVH_SECRET=$( domain ovh.secret $fqdn_config );
  export OVH_CONSUMER_KEY=$( domain ovh.consumer_key $fqdn_config );

  mkdir -p "$output";

  local templates=$( app templates );
  local template=$( domain ovh.template $fqdn_config );
  template=$( path "$templates/$template" );

  local template_engine=$( app template_engine );
  template_engine=$( path $template_engine );

  source <($template_engine $template) > "$credentials";
  if [[ $? != 0 ]]
  then
    error "During OVH credentials file generation";
    return 1;
  fi
  
  info "<% level 2 %>  OVH credentials file generated" "$fqdn";

  chmod 600 "$credentials";
  if [[ $? != 0 ]]
  then
    error "Making OVH credentials file readable only by the owner";
    return 1;
  fi

  info "<% level 2 %> OVH credentials file is now only readable by the owner" "$fqdn";
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