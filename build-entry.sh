#!/bin/bash

REPO_OWNER=${REPO%/*}
REPO_NAME=${REPO##*/}

PAGE_URL=https://${REPO_OWNER}.github.io/${REPO_NAME}

cat <<EOF >dist/README.md
# Generated repository

You can use this repository by:
1. Adding the repository to your sources list:
	\`\`\`bash
	echo "deb [trusted=yes] $PAGE_URL unstable main" | sudo tee /etc/apt/sources.list.d/aaropa-repo.list
	\`\`\`
2. Run \`sudo apt update\`
3. Install keyring package:
	\`\`\`bash
	wget -q $PAGE_URL/$(find dist -type f -iname "aaropa-keyring_*.deb" -print -quit | sed 's|dist/||') -O aaropa-keyring.deb
	sudo apt install aaropa-keyring
	\`\`\`
4. Install packages from this repository:
	\`\`\`bash
	sudo apt install <package-name>
	\`\`\`

Files in this repo:

EOF

find dist -type f | sed 's|^dist/||' | while read -r file; do
	cat <<EOF >>dist/README.md
- [$file]($PAGE_URL/$file)
EOF
done
