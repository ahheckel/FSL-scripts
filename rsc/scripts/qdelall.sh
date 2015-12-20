#!/bin/bash

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

$(dirname $0)/qdel.sh all
