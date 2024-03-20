#!/bin/bash

environment=$1
profile=$2
provider=${3:-aws}
autoAnswer=${4-no}
globalAnswer="no"
autoApprove=""

if [ $autoAnswer = "yes" ];then
  globalAnswer=$autoAnswer;
  autoApprove="-auto-approve"
fi



cmd="aws-profile -p upscan-labs  terraform state replace-provider $autoApprove -lock=true -lock-timeout=30s -- -/$provider hashicorp/$provider"


usage(){
  echo "replace-provider 'labs | live'  'development | qa | staging' 'provider'  'yes | no'"
  echo "this script runs "$cmd""
}


for arg in "$@"; do
    case $arg in
        --env=*)
            environtment=${arg#*=}
            ;;
    esac
done

ask_continue() {
    local message=$1
    if [ $globalAnswer = "yes" ]; then
      echo "$message: y"
      choice="y"
    else
      read -p "$message (y/n): " choice
    fi

    if [ "$choice" = "y" ] || [ "$choice" = "Y" ]; then
        return 0
    else
        return 1
    fi
}

do_cmd(){
  if ask_continue  "Running in $environment";then	
	  local cwd=$(pwd)
		for dir in "$cwd/components/"*/; do
	    if [ -d "$dir" ]; then
	      (cd $dir
	        if ask_continue "About to run $cmd for $dir";then
	          rm -rf .terraform/
	          aws-profile -p upscan-${environment} terraform init --backend-config=../../backends/${profile}.tfvars
	          aws-profile -p upscan-${environment} terraform workspace select ${profile}
	          $cmd
	        fi)
	  fi
	  done
  else
	echo "Exiting"
  fi
}


if [ "$environment" = "labs" ] || [ "$environment" = "live" ]; then
  if [ "$profile" = "development" ] || [ "$profile" = "qa" ] || [ "$profile" = "staging" ]; then
    do_cmd
  else
    usaage
    exit 1
  fi

else
  usage
  exit 1
fi
