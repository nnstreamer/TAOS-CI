#!/bin/bash
./gen-diff-patch.sh

# investigate generated all *.patch files
for i in *.patch; do
	# FIXME: Handle in case that there are multiple files in one commit.
	cat $i | grep '^\\ No newline' > /dev/null
	if  [[ $? == 0 ]]; then
		echo "[DEBUG] Failed. patch file name: $i"
		echo "[DEBUG] current directory is `pwd`"
		newline_pass=0
	else
		echo "[DEBUG] Passed. patch file name: $i"
		echo "[DEBUG] current directory is `pwd`"
		newline_pass=1
	fi
	# Binary handling: Let's do not check "No newline" statement in case of *.bin files
	bin_num=$(cat $i | grep "diff --git" | grep ".bin" | wc -l)
	if  [[ $bin_num > 0 ]]; then
		newline_pass=1
	fi
done

if [[ $newline_pass == 0 ]]; then
	exit 1
fi
