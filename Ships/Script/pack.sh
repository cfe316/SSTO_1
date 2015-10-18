# This file is distributed under the terms of the MIT license, (c) the KSLib team

# The purpose of this file is to decrease size of .ks files for the final flight. However, please upload 
# UNPACKED versions of programs to KSLib.

# This version works in Unix environments.

# Run this file while being in your scripts directory. 
# It will put the packed versions in the same directory as this script.

FILES=`ls source/*.ks`
echo $FILES
for f in $FILES; do
	sed \
	-e 's/^\(\([^"]*\)\("[^"]*"[^"]*\)*\)\/\/.*/\1/g' \
	-e 's/^\( \|\t\)*//g' \
	-e 's/\( \|\t\)*$//g' \
	-e '/^\s*$/d' \
	$f > $(basename $f);
	# the first line strips comments
	# the second line strips leading whitespace
	# the third line strips trailing whitespace
done
