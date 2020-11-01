#!/usr/bin/env bash
################################################################################
# See doc from https://sookocheff.com/post/bash/parsing-bash-script-arguments-with-shopts/
################################################################################

# Default values.
kubeconfig_secret_id='kubeconfig'
workdir="terraform"
kubeconfig_dir="~/.kube"

################################################################################
# Help
################################################################################
Help() {
  # Display Help
  echo "Apply Terraform."
  echo "Usage:"
  echo "  -h                        - display this message."
  echo "  -w <workingdir path>      - workdir for terraform. (default terraform)"
  echo "  -s <secret_id>            - secret id in AWS SecretsManager to get kubeconfig. (default kubeconfig)"
  echo "  -k <kubeconfig location>  - directory location for kubeconfig. (default ~/.kube)"
  echo "Syntax: ./apply.sh -h -w -k"
  echo
}

################################################################################
# Retrieve Kubeconfig from AWS Secretsmanager
################################################################################
Kubeconf(){
  if [[ -d "$1" && -f "$1/config" ]]; then
    echo "Kubeconfig already exists, don't retrieve from AWS SecretsManager"
  else
    echo "Read kubeconf from secretsmanager secret secret id '$2' and store in '$1/config'.."
    mkdir $1 && aws secretsmanager get-secret-value --secret-id $2 | jq --raw-output '.SecretString' > $1/config;
  fi
}

################################################################################
# Apply                                                                        #
################################################################################
Apply() {
  echo "Apply Terraform on environment '$1'.."
  terraform init -input=false "$1"
  terraform apply -target module.template.module.traefik -auto-approve "$1"
  terraform apply -auto-approve "$1"
  terraform apply -auto-approve "$1"
}

################################################################################
# Get options                                                                  #
################################################################################
while getopts ":hw:s:k:" opt; do
  case ${opt} in
    h ) # process option help
      Help
      exit 0
      ;;
    k ) # process option terraform workdir
      kubeconfig_dir=$OPTARG
      ;;
    w ) # process option terraform workdir
      workdir=$OPTARG
      ;;
    s ) # process option kubeconfig secret id
      kubeconfig_secret_id=$OPTARG
      ;;
    \? )
      echo "Invalid Option: -$OPTARG" 1>&2
      exit 1
      ;;
    : )
      echo "Invalid Option: -$OPTARG requires an argument" 1>&2
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

################################################################################
# Main Logic                                                                   #
################################################################################
echo "Working Directory: $workdir"
echo "Kubeconfig Secret Id: $kubeconfig_secret_id"
echo "Kubeconfig Directory: $kubeconfig_dir"

Kubeconf $kubeconfig_dir $kubeconfig_secret_id
Apply $workdir
