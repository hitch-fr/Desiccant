#!/usr/bin/env bash
# Desiccant by Eachtime https://github.com/eachtime
# Version : 0.1
# website: https://desiccant.fr
#
# This script is licensed under The GNU AFFERO GENERAL PUBLIC LICENSE.
# Please read the LICENSE file in the project root for more details 

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
source $APP/log/functions.sh;
source $APP/cron/common.sh;

# source $FUNCTIONS/logger.sh;
source $FUNCTIONS/reporter.sh;
source $FUNCTIONS/openssl.sh;
source $FUNCTIONS/dehydrated.sh;
source $FUNCTIONS/sync.sh;

# unset temporary variables
unset -v FUNCTIONS;
unset -v APP;