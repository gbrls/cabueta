#!/bin/bash


if [[ "$OSTYPE" == "darwin"* ]]; then
	brew install nuclei semgrep gitleaks osv-scanner jq glow
#elif [[ `uname -rv | grep 'Debian'` ]]; then
#	echo "debian";
else
	echo "OS not detected; install nuclei, osv-scanner, gitleaks, and semgrep for your OS/Distro"
fi

