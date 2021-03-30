#!/usr/bin/env bash
################################################################################
# Help
################################################################################
Help() {
  # Display Help
  echo "Update Version so that Terraform knows which version to deploy."
  echo ""
  echo "Usage:"
  echo "  <version>                 - The new version"
  echo "  <application>             - The application to set version for"
  echo "  <name prefix>             - The name prefix to set version for"
  echo "  -h                        - Display this message."
  echo ""
  echo "Syntax: ./version.sh <version> <application> <name prefix>"
  echo
}

################################################################################
# Set Version                                                                        #
################################################################################
SetVersion() {
  local version=$1
  local application=$2
  local nameprefix=$3
  echo "Set version '$version' for '$application' in '$nameprefix'"
  aws ssm put-parameter --overwrite true --name "/versions/$nameprefix/$application" --type "String" --value "$version"
}

################################################################################
# Get positional arguments                                                     #
################################################################################
echo "# Arguments: $@"
if (( $# < 3 )); then
  Help
  exit 0
else
  version="$1"; shift
  application="$1"; shift
  nameprefix="$1"; shift
fi

################################################################################
# Get options                                                                  #
################################################################################
while getopts ":h" opt; do
  case ${opt} in
    h ) # process option help
      Help
      exit 0
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
printf "# Version\t:$version\n"
printf "# Application\t:$application\n"
printf "# Name Prefix\t:$nameprefix\n"

SetVersion $version $application $nameprefix
