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