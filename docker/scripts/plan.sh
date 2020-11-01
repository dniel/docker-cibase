#!/usr/bin/env bash
################################################################################
# entrypoint script for docker container
################################################################################

Plan() {
  echo "Plan Terraform on environment '$1'.."
  cd envs/$1 || exit
  ls -la
  terraform init -input=false
  terraform plan -detailed-exitcode
}