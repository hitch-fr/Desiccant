#!/usr/bin/env bash
set -Eeuo pipefail
APP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )";

export DESICCANT_PWD=${APP%/*};
export DESICCANT_JQ="$DESICCANT_PWD/libs/jq-linux64";

FUNCTIONS=$DESICCANT_PWD/functions;

source $FUNCTIONS/utils.sh;
source $FUNCTIONS/helpers.sh;
source $FUNCTIONS/logger.sh;
source $FUNCTIONS/reporter.sh;
source $FUNCTIONS/openssl.sh;
source $FUNCTIONS/dehydrated.sh;
source $FUNCTIONS/sync.sh;

unset -v FUNCTIONS;
unset -v APP;