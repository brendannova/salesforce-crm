#!/bin/bash

# Ensure xmlstarlet is installed
command -v xmlstarlet >/dev/null 2>&1 || { echo "xmlstarlet is required but not installed."; exit 1; }

# Loop through all XML files in current directory (non-recursive)
for file in $(find . -type f -name "*.namedCredential-meta.xml"); do
  [ -f "$file" ] || continue

  echo "Processing $file"

  # Add <password>NOPASSWORD</password> after <protocol>password</protocol>, ignoring namespaces
  xmlstarlet ed -L \
    -a "//*[local-name()='protocol' and text()='Password']" \
    -t elem -n "password" -v "NOPASSWORD" \
    -u "//*[local-name()='protocol' and text()='Password']/../*[local-name()='username']" \
    -v "NOUSER" \
    "$file"
done

for file in $(find . -type f -name "*.authprovider-meta.xml"); do
  [ -f "$file" ] || continue

  echo "Processing $file"

  # Add <password>NOPASSWORD</password> after <protocol>password</protocol>, ignoring namespaces
  xmlstarlet ed -L \
  -u "//*[local-name()='AuthProvider']/*[local-name()='consumerKey']"    -v "NOKEY" \
  -u "//*[local-name()='AuthProvider']/*[local-name()='authorizeUrl']"   -v "https://example.com" \
    "$file"
done

