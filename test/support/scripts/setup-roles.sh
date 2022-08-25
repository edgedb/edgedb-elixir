#!/usr/bin/env bash

set -e

edgedb query --file test/support/scripts/edgeql/setup-roles.edgeql
