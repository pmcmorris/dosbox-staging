#!/bin/bash -e

# Copyright (C) 2020  Patryk Obara <patryk.obara@gmail.com>
# SPDX-License-Identifier: GPL-2.0-or-later

readonly SCRIPT=$(basename "$0")

print_usage () {
	echo "usage: $SCRIPT [-V|--verify|-a|--amend] [<commit>]"
	echo
	echo "Fixes formatting of C and C++ files, that were touched by "
	echo "commits since <commit>.  Changes are limited only to files and "
	echo "lines that were modified. If a file was moved/renamed and only "
	echo "slightly modified (less than 10%), then it's not reformatted."
	echo
	echo "If no <commit> is passed, then default is HEAD~1 - which means "
	echo "that only lines touched by the latest commit will be fixed, "
	echo "therefore usage of this script is simply:"
	echo
	echo "  $ ./format-code"
	echo
	echo "Files are formatted only if .clang-format file is located in one "
	echo "of the parent directories of the source file."
	echo
	echo "Optional parameter --verify displays diff of what was formatted "
	echo "and exits with a failure status if diff is not empty."
	echo
	echo "Optional parameter --amend will amend the latest commit for you."
	echo
	echo "If you want to format a whole specific file instead use "
	echo "clang-format directly, e.g.:"
	echo
	echo "  $ clang-format -style=file path/to/file.cpp"
}

main () {
	case $1 in
		-h|-help|--help) print_usage ;;
		-V|--verify)     handle_dependencies ; shift ; format "$@" ; assert_empty_diff ;;
		-a|--amend)      handle_dependencies ; shift ; format "$@" ; amend ;;
		*)               handle_dependencies ; format "$@" ;;
	esac
}

handle_dependencies () {
	assert_min_version git 1007010 "Use git in version 1.7.10 or newer."
	assert_min_version clang-format 3009000 "Use clang-format in version 3.9.0 or newer."
}

assert_min_version () {
	if ! check_min_version "$1" "$2" ; then
		echo "$3"
		exit 1
	fi
}

check_min_version () {
	echo "+ $1 --version"
	$1 --version
	$1 --version \
		| sed -e "s|.* \([0-9]*\)\.\([0-9]*\)\.\([0-9]*\).*|\1 \2 \3|" \
		| test_version "$2"
	return "${PIPESTATUS[2]}"
}

test_version () {
	read -r major minor patch
	local -r version=$((major * 1000000 + minor * 1000 + patch))
	test "$1" -le "$version"
}

format () {
	local -r since_ref=${1:-HEAD~1}
	pushd "$(git rev-parse --show-toplevel)" > /dev/null
	find_cpp_files "$since_ref" | run_clang_format
	popd > /dev/null
}

assert_empty_diff () {
	if [ -n "$(git_diff HEAD)" ] ; then
		git_diff HEAD
		echo 'Run "./format-code" to fix formatting in your commit.'
		echo
		exit 1
	fi
}

amend () {
	git commit -a --amend
}

git_diff () {
	git diff --no-ext-diff "$@"
}

find_cpp_files () {
	set +e
	list_changed_files "$1" | grep -E "\.(h|hpp|c|cpp|cc)$"
	set -e
}

list_changed_files () {
	git_diff \
		--no-renames \
		--diff-filter=AMrcd \
		--find-renames=90% \
		--find-copies=90% \
		--name-only \
		"$1"
}

run_clang_format () {
	while read -r file ; do
		if style_configuration_exists "$file" ; then
			prepare_clang_params "$file" \
				| xargs clang-format -i -style=file
		fi
	done
}

style_configuration_exists () {
	local -r dir=$(dirname "$1")
	local -r format_file=$dir/.clang-format
	local -r blacklist_file=$dir/.clang-noformat
	if [ -f "$blacklist_file" ] ; then
		return 1
	fi
	if [ -f "$format_file" ] ; then
		return 0
	fi
	if [ "$dir" = "." ] ; then
		return 1
	fi
	style_configuration_exists "$dir"
}

prepare_clang_params () {
	local -r file=$1
	git_diff --ignore-space-at-eol -U0 HEAD~1 "$file" \
		| grep -E "^@@" \
		| filter_line_range \
		| to_clang_line_range
	echo "\"$file\""
}

# expects line in diff format: "@@ -<line range> +<line range> @@ <context>"
# where <line range> is either <line_number> or <line_number>,<offset>
#
filter_line_range () {
	sed -e 's|@@ .* +\([0-9]\+\),\?\([0-9]\+\)\? @@.*|\1 \2|'
}

to_clang_line_range () {
	while read -r from_line offset ; do
		local to_line=$(( from_line + offset ))
		if [[ $from_line -gt 0 && $from_line -le $to_line ]] ; then
			echo "-lines=$from_line:$to_line"
		fi
	done
}

main "$@"
