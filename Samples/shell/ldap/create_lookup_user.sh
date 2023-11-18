#!/bin/bash

# This script takes two arguments: the first one is
# the sAMAccountName of the user to be created, the second one
# is the ldap provider name.

# Check that exactly two arguments were passed.
if [ $# -ne 2 ]; then
  echo "The first argument is sAMAccount, the second argument is ldap provider name"
  exit 1
fi

# Create the user. We assume the user's full name is the same as the sAMAccountName.
oc create user $1 --full-name="$1"

# Create the identity, remove the trailing '=' from the base64 encoded string.
ldap_string=`echo -n $1 | base64 | tr -d '='`
oc create identity $2:$ldap_string

# Create the user identity mapping.
oc create useridentitymapping $2:$ldap_string $1