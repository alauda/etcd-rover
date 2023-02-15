#!/bin/bash

echo "load drbd"
/load-drbd.sh

echo "start tiebreaker"
/tiebreaker.sh "$@"

