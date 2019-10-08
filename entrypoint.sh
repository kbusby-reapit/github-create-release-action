#!/bin/bash
################################################################################
# Descrição:
#   Script Github Actions to create a new release automatically
################################################################################

set -e
set -o pipefail

# ============================================
# Function to create a new release in Github API
# ============================================
request_create_release(){

	local json_body='{
	  "tag_name": "@tag_name@",
	  "target_commitish": "@branch@",
	  "name": "@release_name@",
	  "body": "@description@",
	  "draft": false,
	  "prerelease": @prerelease@
	}'
		
	json_body=$(echo "$json_body" | sed "s/@tag_name@/$git_tag/")
	json_body=$(echo "$json_body" | sed "s/@branch@/master/")
	json_body=$(echo "$json_body" | sed "s/@release_name@/$release_name/")
	json_body=$(echo "$json_body" | sed "s/@description@/$DESCRIPTION/")
	json_body=$(echo "$json_body" | sed "s/@prerelease@/$prerelease/")
		
	curl --request POST \
	  --url https://api.github.com/repos/${GITHUB_REPOSITORY}/releases \
	  --header "Authorization: Bearer $GITHUB_TOKEN" \
	  --header 'Content-Type: application/json' \
	  --data "$json_body"
}

# ==================== MAIN ====================

# Ensure that the GITHUB_TOKEN secret is included
if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "Set the GITHUB_TOKEN env variable."
  exit 1
fi
if [[ ${GITHUB_REF} = "refs/heads/master" || ${GITHUB_REF} = "refs/heads/development" ]]; then
	if [[ ${GITHUB_REF} = "refs/heads/development" ]]; then
		prerelease=true
	else
		prerelease=false
	fi
	last_tag_number=$(git describe --tags $(git rev-list --tags --max-count=1))

	# Create new tag.
	if [[ $last_tag_number == *"RC"* ]]; then
  		current_rc_version="${last_tag_number: -1}"
		next_rc_version=$((current_rc_version+1))
		new_tag="${last_tag_number::-1}$next_rc_version"
		release_name="$("$new_tag" | tr 'RC' 'Release Candidate')"
	fi
	
	echo "The next release name will be $release_name"
	echo "The current RC version for this sprint is: $current_rc_version"
	echo "The next RC version for this sprint is: $next_rc_version"
	
	
	echo "The new tag is going to be called: $new_tag"
	
	git_tag="${new_tag}"
	request_create_release

	# If null, is the first release (code checks if it is the first release. Unnecessary for now.
	#if [ $(git tag | wc -l) = "0" ];then
	#	git_tag="v1.0"
	#	request_create_release
	#else
	#	new_tag=$(echo "$last_tag_number + 1" | bc)
	#	git_tag="v${new_tag}.0"
	#	request_create_release
	#fi
else
	echo "This Action run only in master branch"
	exit 0
fi
