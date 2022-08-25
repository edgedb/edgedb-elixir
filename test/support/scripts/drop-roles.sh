#!/usr/bin/env bash

set -e

edgedb query --file test/support/scripts/edgeql/drop-roles.edgeql
