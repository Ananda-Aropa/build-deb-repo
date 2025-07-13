#!/bin/bash

LOG=$(pwd)/log.txt

touch $LOG

# Download functions take first argument as the target URL
# and the rest as additional arguments as headers with format
# <HEADER>: <VALUE>

# Function to download files using aria2c
download_with_aria2c() {
	local target=$1 out aria2c_opts="" header
	shift
	if [ "$#" -gt 0 ]; then
		out="-o $1"
		shift
	else
		out=""
	fi
	for header in "$@"; do
		# Add headers to aria2c options
		aria2c_opts="$aria2c_opts --header='$header' "
	done
	aria2c -x 8 -s 8 --max-tries=$MAX_RETRIES --retry-wait=$RETRY_WAIT $aria2c_opts $out "$target" >$LOG 2>&1 &&
		echo "Downloaded $1 using aria2c..."
}

# Function to download files using wget
download_with_wget() {
	local target=$1 out wget_opts="" header
	shift
	if [ "$#" -gt 0 ]; then
		out="-O $1"
		shift
	else
		out=""
	fi
	for header in "$@"; do
		# Add headers to wget options
		wget_opts="$wget_opts --header='$header' "
	done
	wget -c --tries=$MAX_RETRIES --waitretry=$RETRY_WAIT $wget_opts $out "$target" >$LOG 2>&1 &&
		echo "Downloaded $target using wget..."
}

# Function to download files using curl
download_with_curl() {
	local target=$1 out curl_opts="" header
	shift
	if [ "$#" -gt 0 ]; then
		if [ "$1" == - ]; then
			out=""
		else
			out="-o $1"
		fi
		shift
	else
		out="-O"
	fi
	for header in "$@"; do
		# Add headers to curl options
		curl_opts="$curl_opts -H '$header' "
	done
	# Use curl to download the file
	curl --retry $MAX_RETRIES --retry-delay $RETRY_WAIT $curl_opts -L $out "$target" >$LOG 2>&1 &&
		echo "Downloaded $1 using curl..."
}

# avoid command failure
exit_check() { [ "$1" = 0 ] || exit "$1"; }
trap 'exit_check $?' EXIT

ARCH=($(grep Architectures dist/conf/distributions | awk -F : '{print $2}'))
SIGNKEY=$(grep SignWith dist/conf/distributions | awk '{print $2}' || :)

if [ -z "$DL" ]; then
	for cmds in aria2c wget curl; do
		if command -v "$cmds" &>/dev/null; then
			DL=$cmds
			break
		fi
	done
fi
export DOWNLOAD="download_with_$DL"

for url in $METADATA_LINKS; do
	# Download metadata
	if ! $DOWNLOAD "${url}/metadata.yml"; then
		echo "WARNING: Repository '$url' does not provide a metadata.yml. Skipping..."
		continue
	fi

	repo_name=$(grep Name metadata.yml | awk '{print $2}')
	repo_ver=$(grep Version metadata.yml | awk '{print $2}')
	repo_variants=($(grep Variants metadata.yml | awk -F : '{print $2}'))
	repo_uvariants=($(grep UdebVariants metadata.yml | awk -F : '{print $2}'))
	rm -f metadata.yml

	for arch in "${ARCH[@]}"; do
		[ "$arch" = source ] && arch=all

		base_name=${repo_name}_${repo_ver}_${arch}
		$DOWNLOAD "${url}/${base_name}.buildinfo"
		$DOWNLOAD "${url}/${base_name}.changes"

		# Sign the .changes file
		if [ "$SIGNKEY" ]; then
			[ "$SIGNKEY" = "yes" ] && sign_key= || sign_key=$SIGNKEY
			./debsign.sh ${SIGNKEY:+-k "$sign_key"} "${base_name}.changes"
		fi

		# Download .deb
		for variant in "${repo_variants[@]}"; do
			$DOWNLOAD "${url}/${variant}_${repo_ver}_${arch}.deb"
			# Also download debug symbol if available
			$DOWNLOAD "${url}/${variant}-dbgsym_${repo_ver}_${arch}.deb"
		done

		# Download .udeb
		for variant in "${repo_uvariants[@]}"; do
			$DOWNLOAD "${url}/${variant}_${repo_ver}_${arch}.udeb"
		done
	done
done

GITHUB_HEADERS=(
	"Accept: application/vnd.github+json"
	"Authorization: Bearer $TOKEN"
	"X-GitHub-Api-Version: 2022-11-28"
)
GITHUB_API="https://api.github.com/repos/"
for repo in $ACTION_LINKS; do
	OWNER=$(echo "$repo" | cut -d '/' -f 1)
	REPO=$(echo "$repo" | cut -d '/' -f 2 | cut -d '@' -f 1)
	REF=$(echo "$repo" | cut -d '@' -f 2 | cut -d ':' -f 1)
	WORKFLOW=$(echo "$repo" | cut -d ':' -f 2)
	WORKFLOW=${WORKFLOW:-"build_deb.yml"}

	workflow_args="status=success&per_page=1"
	[ "$REF" ] && workflow_args="$workflow_args&branch=$REF"

	# Get latest workflow run
	# $GITHUB_API/repos/$OWNER/$REPO/actions/workflows/$WORKFLOW/runs
	latest_workflow_info=$($DOWNLOAD "$GITHUB_API/$OWNER/$REPO/actions/workflows/$WORKFLOW/runs?${workflow_args}" - "${GITHUB_HEADERS[@]}")
	latest_run_url=$(echo "$latest_workflow_info" | jq -r '.workflow_runs[0].url')
	latest_artifact_info=$($DOWNLOAD "$latest_run_url/artifacts" - "${GITHUB_HEADERS[@]}")
	latest_artifact_download_url=$(echo "$latest_artifact_info" | jq -r '.artifacts[0].archive_download_url')

	if [ -z "$latest_artifact_download_url" ]; then
		echo "WARNING: No artifacts found for workflow '$WORKFLOW' in repository '$repo'. Skipping..." >$LOG
		continue
	fi

	# Download the latest artifact
	$DOWNLOAD "$latest_artifact_download_url" artifact.zip "${GITHUB_HEADERS[@]}"

	# Unzip the artifact
	unzip -o artifact.zip -d . >$LOG 2>&1 || {
		echo "ERROR: Failed to unzip artifact for repository '$repo'. Skipping..." >$LOG
		continue
	}
	rm -f artifact.zip

	# Sign the .changes file
	if [ "$SIGNKEY" ]; then
		[ "$SIGNKEY" = "yes" ] && sign_key= || sign_key=$SIGNKEY
		./debsign.sh ${SIGNKEY:+-k "$sign_key"} *.changes
	fi
done

mkdir -p indie_debs
cd indie_debs
for pkg in $DEB_LINKS; do
	# Download .deb
	if ! $DOWNLOAD "$pkg"; then
		echo "WARNING: Package '$pkg' not found. Skipping..."
		continue
	fi
done
cd ..

find . -type f -iname '*.deb' >$LOG

{
	cd dist
	for changes in ../*.changes; do
		reprepro include $RELEASE "$changes"
	done
	ls ../indie_debs/*.deb 2>/dev/null && {
		for deb in ../indie_debs/*.deb; do
			reprepro includedeb $RELEASE "$deb"
		done
	} || :
}

cat $LOG
