#!/usr/bin/env bash

set -e

edgedb query --file priv/scripts/edgeql/setup-roles.edgeql
