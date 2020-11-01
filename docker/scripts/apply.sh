#!/usr/bin/env bash
################################################################################
# See doc from https://sookocheff.com/post/bash/parsing-bash-script-arguments-with-shopts/
################################################################################

# Default values.
kubeconfig_secret_id='kubeconfig'
workdir="."
download_dir="/tmp/terraform"
kubeconfig_dir="$HOME/.kube"
kubeconfig_file="config"

################################################################################
# Help
################################################################################
Help() {
  # Display Help
  echo "Apply Terraform."
  echo "Usage:"
  echo "  <s3 path>                 - The path to zip-file containing terraform code in S3"
  echo "  -h                        - display this message."
  echo "  -d <download dir>         - where the s3 file is downloaded and unzipped. (default /tmp/terraform)"
  echo "  -w <workdir path>         - workdir for terraform, relative to download dir. (default .)"
  echo "  -s <secret_id>            - secret id in AWS SecretsManager to get kubeconfig. (default kubeconfig)"
  echo "  -k <kubeconfig location>  - directory location for kubeconfig. (default ~/.kube)"
  echo "Syntax: ./apply.sh s3://path/to/terraform/artifact.zip -h -w -k"
  echo
}

s3_url=$1;
if [[ $# != 1 ]]; then
  Help
  exit 1
fi

################################################################################
# Retrieve Kube config from AWS SecretsManager
################################################################################
Kubeconf(){
  local kubeconfig_dir=$1
  local kubeconfig_file=$kubeconfig_dir/config
  local secret_id=$2

  if [[ -d "$kubeconfig_dir" && -f "$kubeconfig_file" ]]; then
    echo "'$kubeconfig_file' already exists, don't retrieve from AWS SecretsManager"
  else
    echo "Read kubeconf from SecretsManager secret secret id '$secret_id' and store in '$kubeconfig_file'.."
    mkdir -p $kubeconfig_dir && aws secretsmanager get-secret-value --secret-id $secret_id | jq --raw-output '.SecretString' > $kubeconfig_file;
  fi
}

################################################################################
# Apply                                                                        #
################################################################################
Apply() {
  local workdir=$1
  echo "Apply Terraform on environment '$workdir'.."
  terraform init -input=false "$workdir"
  terraform apply -target module.template.module.traefik -auto-approve "$workdir"
  terraform apply -auto-approve "$workdir"
}

################################################################################
# Download And Unzip                                                           #
################################################################################
DownloadAndUnzip(){
  local s3_url=$1
  local s3_filename=${s3_url##*/}
  local download_dir=$2

  echo "Download artifact from '$s3_url'"
  echo "Download artifact filename '$s3_filename'"

  if [[ -d "$download_dir" ]]; then
    echo "Donwload dir '$download_dir' already exists."
  else
    echo "Create Donwload dir '$download_dir'.."
    mkdir -p $download_dir
  fi

  echo "Download terraform code from S3 artifact."
  aws s3 cp $s3_url $download_dir/$s3_filename
  unzip $download_dir/$s3_filename -d $download_dir
}

################################################################################
# Get options                                                                  #
################################################################################
while getopts ":hw:s:k:d:" opt; do
  case ${opt} in
    h ) # process option help
      Help
      exit 0
      ;;
    d )
      download_dir=$OPTARG
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

echo "S3 Url: $s3_url"
echo "Working Directory: $workdir"
echo "Kubeconfig Secret Id: $kubeconfig_secret_id"
echo "Kubeconfig Directory: $kubeconfig_dir"

DownloadAndUnzip $s3_url $download_dir
Kubeconf $kubeconfig_dir $kubeconfig_secret_id
Apply $workdir
