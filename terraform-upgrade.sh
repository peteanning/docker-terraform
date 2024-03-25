#!/bin/bash

set -ux

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
    "waf_ac"
)

initialise_commands() {
  echo "Setting up commands for $environment in the $profile workspace"  
  awsProfile="aws-profile -p upscan-$environment"	
  initCmd="$awsProfile terraform init --backend-config=../../backends/$profile.tfvars"
  selectProfileCmd="$awsProfile terraform workspace select $profile"	
  savePlanCmd="$awsProfile terraform plan -out tfplan.out"
  applyCmd="$awsProfile terraform apply tfplan.out"  
}

upgrade() {
  echo "Upgrading from $fromVersion to $toVersion"
  for c  in "${validComponents[@]}"; do
    local dir="$cwd/$c"

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
    
    # Navigate back to the parent directory
    cd ..
  done
}

usage() {
    echo "Usage: $0 [-u | --upgrade] [-f | --from <version>] [-t | --to <version>]"
    echo "Options:"
    echo "  -u, --upgrade    Perform upgrade"
    echo "  -f, --from       Specify the version to upgrade from"
    echo "  -t, --to         Specify the version to upgrade to"
}

for arg in "$@"; do
    case $arg in
        -u|--upgrade)
            upgradeFlag=true
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
    if [[ "$profile" != "development" ]] && [[ "$profile" != "qa" ]] && [[ "$profile" != "staging" ]] && [[ "$profile" != "externalTest" ]] && [[ "$profile" != "production" ]]; then
       usage
       exit 1
    fi
    initialise_commands
    if [[ "$component" = "*" ]]; then
      upgrade
      exit 0
    elif [[ " ${validComponents[@]} " =~ " $component " ]]; then
	    echo "Upgrading $component"
    else
	    echo "Invalid $component specified"
	    echo "Should be one of ${components[@]}"
	    exit 1
    fi
else
    usage
fi

