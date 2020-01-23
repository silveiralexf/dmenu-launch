#!/bin/bash
#-------------------------------------------------------------------------------
#  File       : dmenu_launch.sh
#  Author     : Felipe A. Silveira (felipe.alexandre@gmail.com)
#  Repository : https://github.com/fsilveir/dmenu-launch
#
#-------------------------------------------------------------------------------
#  SCRIPT DESCRIPTION
#-------------------------------------------------------------------------------
#
#  Synopsis    : Simple dmenu launcher for passwords, docs, notes and shortcuts.
#
#  Requirements: pass, gpg, dmenu, xclip, exo-open, pkill
#
#  Arguments:
#   --pass   : Chooses a password from password vault
#   --notes  : Open a personal note with gedit
#   --apps   : Quick launches a desktop application with exo-open
#   --search : Quick search & launch from a given directory with exo-open.
#
#-------------------------------------------------------------------------------
# Globals
#-------------------------------------------------------------------------------

# The following utilities are required for this script to work
REQUIREMENTS="pass gpg dmenu xclip exo-open pkill"

# Default directories for password store, personal notes, and desktop shortcuts
PASSWORD_STORE_DIR="$HOME/.password-store/keys"
PERSONAL_NOTES_DIR="$HOME/git/notes"
DESKTOP_APPS_DIR="/usr/share/applications"
SEARCH_DIR="$HOME/work"

# Extensions to hide from dmenu display
PASSWORD_STORE_EXT=".gpg"
PERSONAL_NOTES_EXT=".md"
DESKTOP_APPS_EXT=".desktop"

# Dmenu font and color schemes
DMENU_FONT="Dejavu Sans Mono:medium:size=18"
DMENU_COLOR_APPS="-nb #191919 -nf #2E9EF4 -sb #2E9EF4 -sf #191919"
DMENU_COLOR_NOTES="-nb #191919 -nf #2aa198 -sb #2aa198 -sf #191919"
DMENU_COLOR_PASS="-nb #191919 -nf #FF0000 -sb #FF9318 -sf #191919"
DMENU_COLOR_SEARCH="-nb #191919 -nf #2aa198 -sb #11D91E -sf #191919"

#-------------------------------------------------------------------------------
# Functions
#-------------------------------------------------------------------------------

main() {
	check_requirements
	get_dmenu_settings "$@"
	get_dmenu_input
	take_action
}

take_action() {
	if [[ $arg == "--pass" ]]; then
		pass show -c "keys/${result}" 2>/dev/null
		echo "$result" | head -n 1 | tr -d "\n" | awk -F "/" '{print $NF}' | xclip
		sleep 10 && pkill xclip
	elif [[ $arg == "--notes" ]]; then
		exo-open "${prefix}/${result}.md"
	elif [[ $arg == "--apps" ]]; then
		exo-open "${prefix}/${result}${suffix}" &>/dev/null
    elif [[ $arg == "--search" ]]; then
		exo-open "${prefix}/${result}"
	fi
}

get_dmenu_input() {
	shopt -s nullglob globstar
	item=( "$prefix"/**/*${suffix})
	item=( "${item[@]#"$prefix"/}" )
	item=( "${item[@]%${suffix}}" )

	# not quoting $color_scheme to force word splitting
    result=$(printf '%s\n' "${item[@]}" | dmenu -fn "$DMENU_FONT" $color_scheme)
	[[ -n $result ]] || exit
}

get_dmenu_settings() {
	if [[ $@ == "" ]]; then
		msg_usage_error
	fi
	
	for arg in "$@"
	do
		if [[ $arg == "--pass" ]]; then
			color_scheme="${DMENU_COLOR_PASS}"
			prefix="${PASSWORD_STORE_DIR}"
			suffix="${PASSWORD_STORE_EXT}"
			shift
		elif [[ $arg == "--notes" ]]; then
			color_scheme="${DMENU_COLOR_NOTES}"
			prefix="${PERSONAL_NOTES_DIR}"
			suffix="${PERSONAL_NOTES_EXT}"
			shift
		elif [[ $arg == "--apps" ]]; then
			color_scheme="${DMENU_COLOR_APPS}"
			prefix="${DESKTOP_APPS_DIR}"
			suffix="${DESKTOP_APPS_EXT}"
			shift
		elif [[ $arg == "--search" ]]; then
			color_scheme="${DMENU_COLOR_SEARCH}"
			prefix="${SEARCH_DIR}"
			suffix=""
			shift
		else
			msg_usage_error
		fi
	done
}

check_requirements() {
	for dir_name in "${PASSWORD_STORE_DIR}" \
                    "${PERSONAL_NOTES_DIR}" \
                    "${DESKTOP_APPS_DIR}" \
                    "${SEARCH_DIR}"
	do
		if [ ! -d "${dir_name}" ] ; then
			echo "$(date +%Y-%m-%d): ERROR - Directory '${dir_name}' not found! Exiting!"
			exit 1
		fi
	done

	for UTIL in $REQUIREMENTS
	do
		command -v "$UTIL" &> /dev/null || msg_missed_req
	done
}

msg_missed_req() {
	echo "$(date +%Y-%m-%d): ERROR - Required util '${UTIL}' not found! Exiting!" 
	exit 1
}

msg_usage_error() {
	printf "usage: dmenu_launch [-h] [--pass | --apps | --notes | --search]

Simple dmenu launcher for passwords, notes and application shortcuts.

optional arguments:
  -h, --help  show this help message and exit.
  --pass      Copy password from password store.
  --apps      Quick launches a desktop application with exo-open.
  --notes     Opens a text/markdown note from a given directory with exo-open.
  --search    Quick search and launch from a given directory with exo-open.\n"
	exit 1
}

#-------------------------------------------------------------------------------
# Main
#-------------------------------------------------------------------------------

main "$@"

#-------------------------------------------------------------------------------
# EOF
#-------------------------------------------------------------------------------
