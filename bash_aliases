alias init-labs-development='aws-profile -p upscan-labs terraform init --backend-config=../../backends/development.tfvars'
alias select-development-profile='aws-profile -p upscan-labs terraform workspace select development'
alias save-plan='aws-profile -p upscan-labs terraform plan -out tfplan.out'
alias show-plan-json='aws-profile -p upscan-labs terraform show -json tfplan.out'
alias update-provider='aws-profile -p upscan-labs  terraform state replace-provider -- -/aws hashicorp/aws'

