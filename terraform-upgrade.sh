#!/bin/bash

set -u

upgradeFlag=false
file="versions.tf"
cwd=$(pwd)
profile="UNSET"
initCmd="UNSET"
selectProfileCmd="UNSET"
savePlanCmd="UNSET"
component="*"
validComponents=(
    "clamav"
    "dns"
    "ecs_cluster"
    "ecs_upload_proxy"
    "ecs_verify"
    "iam"
    "nat"
    "network"
    "pagerduty_alerts"
    "s3"
    "s3_sqs_notification"
    "security_groups"
    "sqs"
    "sqs_policy"
    "squid"
    "vpce_artefacts"
    "vpce_cloudwatch"
    "vpce_graphite"
    "vpce_s3"
    "vpce_sqs"
    "vpce_telemetry_kafka"
    "waf_acl"
)

initialise_commands() {
  echo "Setting up commands for $environment in the $profile workspace"  
  awsProfile="aws-profile -p upscan-$environment"	
  initCmd="$awsProfile terraform init -no-color --backend-config=../../backends/$profile.tfvars"
  selectProfileCmd="$awsProfile terraform workspace select -no-color $profile"	
  savePlanCmd="$awsProfile terraform plan -no-color -out tfplan.out"
  applyCmd="$awsProfile terraform apply tfplan.out"  
}

unlock(){
  local lockId=$1
  local unlockCmd="$awsProfile terraform force-unlock $lockId"

  echo "Forcing unlock with: $unlockCmd"
  $unlockCmd
}

upgrade() {
  echo "Upgrading from $fromVersion to $toVersion"
  for c  in "${validComponents[@]}"; do
    local dir="$cwd/components/$c"

    if [[ "$component" = "*" ]] ||  [[ "$c" = "$component" ]]; then

      echo "Looking for $file in $dir"
      cd "$dir" || continue
      if [  -f "$file" ]; then
        echo "Found  $file  in directory: $dir"
        sed -i "s/>= $fromVersion/>= $toVersion/" $file
      fi
  
      if [ -d "$dir/.terraform" ]; then
        echo "Found existing .terraform directory deleting before init"
        rm -rf "$dir/.terraform/"
      fi
  
      echo "Generating the plan after upgrade in tfplan.out"
      echo "To view the plan use aws-profile -p upscan-$environment terraform show -json tfplan.out"
      $initCmd
      $selectProfileCmd
      $savePlanCmd 
      
      cd ..
    else
      echo "Not upgrading $c no match"
    fi      
  done
}

usage() {
    echo "Usage: $0 '--upgrade | --unlock'  --profile=<profile> '--lockid=<id>' | '--from=<version>' '--to=<version>'"
    echo "Options:"
    echo "  --upgrade | --unlock  Perform upgrade or Unlock a component"
    echo "  --lockid              Specify the lockid to unlock (required for --unlock)"
    echo "  --profile             Specify the workspace to be one of: development | qa | staging | externaltest | production"
    echo "  -f, --from            Specify the version to upgrade from (required for --upgrade)"
    echo "  -t, --to              Specify the version to upgrade to (required for --upgrade)"
}

check_profile_and_intialise_cmds(){
    if [[ "$profile" != "development" ]] && [[ "$profile" != "qa" ]] && [[ "$profile" != "staging" ]] && [[ "$profile" != "externalTest" ]] && [[ "$profile" != "production" ]]; then
       usage
       exit 1
    else
      initialise_commands
    fi

}

for arg in "$@"; do
    case $arg in
        --upgrade)
            upgradeFlag=true
            shift
            ;;
        --unlock)
            unlockFlag=true
            shift
            ;;
        --profile=*)
            profile=${arg#*=}
	      case $profile in
		      development|qa|staging)
			      environment=labs
			      ;;
		      externalTest|production)
			      environment=live
			      ;;
		      *)
			      echo "Invalid Profile $profile"
			      usage
			      exit 1
			      ;;
	      esac

	    ;;
        --lockid=*)
            lockId=${arg#*=}
	    ;;
        --from=*)
            fromVersion=${arg#*=}
	    ;;
        --to=*)
            toVersion=${arg#*=}
	    ;;
        --component=*)
            component=${arg#*=}
	    ;;
        *)
            echo "Error: Unknown option $1"
            usage
            exit 1
            ;;
    esac
done

if [ "$upgradeFlag" = true ]; then
    if [ -z "$fromVersion" ] || [ -z "$toVersion" ]; then
        echo "Error: Both -f/--from and -t/--to options are required for upgrade"
        usage
        exit 1
    fi
    check_profile_and_initialise_cmds
    if [[ "$component" = "*" ]]; then
      upgrade
      exit 0
    elif [[ " ${validComponents[@]} " =~ " $component " ]]; then
	    echo "Upgrading $component"
	    upgrade
    else
	    echo "Invalid $component specified"
	    echo "Should be one of ${components[@]}"
	    exit 1
    fi
elif [ "$unlockFlag" = true ]; then
    if [ -z "$lockId" ]; then
      usage
      exit 1
    fi
    check_profile_and_intialise_cmds
    unlock $lockId
else
    usage
fi

