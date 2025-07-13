#!/bin/bash

REPO_OWNER=${REPO%/*}
REPO_NAME=${REPO##*/}

PAGE_URL=https://${REPO_OWNER}.github.io/${REPO_NAME}

cat <<EOF >>dist/index.html
<!DOCTYPE html>
<html lang="en">
<head>
		<meta charset="UTF-8">
		<meta name="viewport" content="width=device-width, initial-scale=1.0">
		<title>Repository</title>
		<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/bulma/0.9.3/css/bulma.min.css">
		<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.3/css/all.min.css">
		<style>
			body {
				background-color: #f5f5f5;
				color: #333;
			}
			.container {
				max-width: 800px;
				margin: 0 auto;
				padding: 20px;
			}
			h1 {
				font-size: 2.5em;
				margin-bottom: 20px;
			}
			ul {
				list-style-type: none;
				padding: 0;
			}
			li {
				margin: 10px 0;
			}
			a {
				text-decoration: none;
				color: #3273dc;
			}
			a:hover {
				color: #363636;
			}			
		</style>
	</head>
	<body>
		<div class="container">
			<h1>Repository</h1>
			<h2>How to use this repository</h2>
			<p>You can use this repository by:</p>
			<ol>
				<li>Adding the repository to your sources list:</li>
				<pre><code>echo "deb [trusted=yes] $PAGE_URL unstable main" | sudo tee /etc/apt/sources.list.d/aaropa-repo.list</code></pre>
				<li>Run <code>sudo apt update</code></li>
				<li>Install keyring package:</li>
				<pre><code>wget -q $PAGE_URL/$(find dist -type f -iname "aaropa-keyring_*.deb" -print -quit | sed 's|dist/||') -O aaropa-keyring.deb<br/>sudo dpkg -i aaropa-keyring.deb</code></pre>
				<li>Install packages from this repository:</li>
				<pre><code>sudo apt install &lt;package-name&gt;</code></pre>
			</ol>
			<h2>Files in this repository</h2>
			<ul>
$(find dist -type f | sed 's|^dist/||' | while read -r file; do
	echo "				<li><a href=\"$PAGE_URL/$file\">$file</a></li>"
done)
			</ul>
		</div>
	</body>
</html>
EOF
