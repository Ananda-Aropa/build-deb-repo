#!/bin/bash

LOG=log.txt

# Function to download files using aria2c
download_with_aria2c() {
  aria2c -x 16 -s 16 "$1" >/dev/null 2>$LOG &&
    echo "Downloaded $1 using aria2c..."
}

# Function to download files using wget
download_with_wget() {
  wget "$1" >/dev/null 2>$LOG &&
    echo "Downloaded $1 using wget..."
}

# Function to download files using curl
download_with_curl() {
  curl -LO "$1" >/dev/null 2>$LOG &&
    echo "Downloaded $1 using curl..."
}

# avoid command failure
exit_check() { [ "$1" = 0 ] || exit "$1"; }
trap 'exit_check $?' EXIT

ARCH=($(grep Architectures dist/conf/distributions | awk -F : '{print $2}'))
SIGNKEY=$(grep SignWith dist/conf/distributions | awk '{print $2}' || :)

for cmds in aria2c wget curl; do
  if command -v "$cmds" &>/dev/null; then
    DOWNLOAD=download_with_$cmds
    break
  fi
done
export DOWNLOAD

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
