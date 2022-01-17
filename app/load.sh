#!/usr/bin/env bash

# Bash failsafe
set -f # disable globbing
set -e # exit on script fail
set -E # ERR trap not fire in certain scenarios with -e only
set -u # exit on var error
# set -x # print commands before exec (debug)
set -o pipefail

# get the app sub directory relative to this file path
APP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )";

# create and export the read only desiccant working directory variable
DESICCANT_PWD=${APP%/*};
export DESICCANT_PWD;

# create and export the JSON Processor executable variable
export DESICCANT_JQ="$DESICCANT_PWD/libs/jq-linux64";

# load desiccant modules ( temporary organization )
FUNCTIONS=$DESICCANT_PWD/functions;

source $APP/core/utils.sh;
source $APP/json/helpers.sh;
source $APP/json/checkers.sh;
source $APP/log/functions.sh;
source $APP/cron/common.sh;
source $APP/send/reports.sh;

source $FUNCTIONS/openssl.sh;
source $APP/core/openssl.sh;
source $APP/core/dehydrated.sh;

# remote functions
source $APP/core/remote.sh;
source $APP/cron/remote.sh;
source $FUNCTIONS/sync.sh;
source $APP/core/sync.sh;

# unset temporary variables
unset -v FUNCTIONS;
unset -v APP;