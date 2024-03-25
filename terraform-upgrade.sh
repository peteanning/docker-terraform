#!/bin/bash

set -u

upgradeFlag=false
file="versions.tf"

upgrade() {
  echo "Upgrading from $froVersion to $toVersion"
  for dir in components/*/; do
    echo "Looking for $file in $dir"
    cd "$dir" || continue
    
    if [  -f "$file" ]; then
      echo "Found  $file  in directory: $dir"
      sed -i 's/>= $fromVersion/>= $toVersion/' $file
    fi
    
    # Navigate back to the parent directory
    cd ..
  done
}

usage() {
    echo "Usage: $0 [-u|--upgrade] [-f|--from <version>] [-t|--to <version>]"
    echo "Options:"
    echo "  -u, --upgrade    Perform upgrade"
    echo "  -f, --from       Specify the version to upgrade from"
    echo "  -t, --to         Specify the version to upgrade to"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--upgrade)
            upgradeFlag=true
            shift
            ;;
        -f|--from)
            fromVersion=$2
            shift 2
            ;;
        -t|--to)
            toVersion=$2
            shift 2
            ;;
        *)
            echo "Error: Unknown option $1"
            usage
            exit 1
            ;;
    esac
done

if [ "$upgrade_flag" = true ]; then
    if [ -z "$from_version" ] || [ -z "$to_version" ]; then
        echo "Error: Both -f/--from and -t/--to options are required for upgrade"
        usage
        exit 1
    fi
    upgrade
else
    usage
fi

