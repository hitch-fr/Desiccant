
renew(){

  local server="${1}" fqdn_config="${2}";

  local fqdn=$( domain fqdn $fqdn_config );
  
  logger_init $fqdn;
  log_header "FQDN : $fqdn";

  info "<% level 1 %> Regenerating the dehydrated domains text file" "$fqdn";
  dehydrated_domain_file $fqdn_config || return 1;
  
  info "<% level 1 %> Regenerating OVH credentials file" "$fqdn";
  generate_ovh_credentials $fqdn_config || return 1;

  local outputs=$( outputs $fqdn_config );
  outputs=$( path $outputs );
  local output="$outputs/$fqdn";
  fullchain=$( path "$output/fullchain.pem" );

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

function renew_all(){

  local servers_conf=$( app hosts );
  servers_conf=$( path "$servers_conf" );
  if ! is_file $servers_conf
  then
    error "the hosts configuration file dont exists";
    return 1;
  fi

  local hosts=$( keys $servers_conf );

  for host in $hosts
  do
    local disabled=$( server $host.disabled );
    if ! is $disabled
    then
      local lockfile=$( app lockfile ); 
      if is_file $lockfile
      then
        warning "LOCKED : renewal is already running";
        return 0;
      fi

      local hostname=$( hostname );
      local targethost=$( server $host.name );

      if [[ $hostname == $targethost ]]
      then
        log_header "BEGINNING : $targethost";
        info "Seeking for certificates configurations on $targethost";
        info "Script starts $( now )";

        lock "$hostname";

        local certs=$( server $host.certificates );

        if is_null $certs
        then
          error "the host $host should have a field 'certificates' that reference your certificates configuration files in an array";
          unlock "$hostname";
          return 0;
        fi

        local confs=$( server $host.confs );
        for cert in $certs
        do
          local fqdn_config=$( path "$confs/$cert" );

          if [[ -f $fqdn_config ]]
          then
            renew $host $fqdn_config || continue;
          else
            log_header " ERROR: $cert"
            error "The configuration file does not exists. Path: $fqdn_config";
          fi
        done

        log_header "ENDING: $targethost";
        unlock "$hostname";
        local report_filename="$( run_name )/report.txt";

        local logdir=$( app logger.directory );
        local report_path=$( path "$logdir/$report_filename" );
        info "Script ending $( now )";

        common_report $report_path $host;

      fi
    fi
  done
}

function sync_all(){

  local servers_conf=$( app hosts );
  servers_conf=$( path "$servers_conf" );

  if ! is_file $servers_conf
  then
    error "the hosts configuration file dont exists";
    return 1;
  fi

  local hosts=$( keys $servers_conf );

  for host in $hosts
  do
    local disabled=$( server $host.disabled );

    if ! is $disabled
    then
      local synchronizable=$( server $host.sync );

      if is $synchronizable
      then
        local hostname=$( hostname );
        local targethost=$( server $host.name );
        log_header "SYNC: $hostname => $targethost";
        sync $host;
        remote_renew $host;
        remote_cronfile $host;
      fi
    fi
  done
}

function hosts_infos(){

  log_header "HOSTS INFOS";

  local servers_conf=$( app hosts );
  servers_conf=$( path "$servers_conf" );

  if ! is_file $servers_conf
  then
    error "the hosts configuration file dont exists";
    return 1;
  fi

  local hosts=$( keys $servers_conf );

  local disabled_hosts="";
  local disabled_count=0;
  
  local enabled_hosts="";
  local enabled_count=0;

  for host in $hosts
  do
    local disabled=$( server $host.disabled );
    local targethost=$( server $host.name );

    if is $disabled
    then
      disabled_hosts+="$targethost, ";
      (( ++disabled_count ));
    else
      enabled_hosts+="$targethost, ";
      (( ++enabled_count ));
    fi
  done

  if ! is_null $disabled_hosts
  then
    info "$enabled_count hosts currently enabled: ${enabled_hosts::-2}";
    info "$disabled_count hosts currently disabled: ${disabled_hosts::-2}";
  fi

}
