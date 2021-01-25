#!/bin/bash
FILE=$1

extract_tags() {
	echo "$( \
		grep "#define" $FILE | \
		cut -d' ' -f2 | \
		cut -d'_' -f1 | \
		awk '!x[$0]++' \
	)"
}

remove_non_numbers() {
	while read l; do
		num="$(echo $l | cut -d' ' -f2)"
		if [[ \
				"${num}" =~ ^0x* && \
				(( 16#"${num#"0x"}" )) && \
				${#num} -ge 2 \
			]] || [[ $num =~ ^[0-9]+$ ]]; then
			echo "$l"
		fi
	done
}

#removes comments
#removes all non-define lines
#removes "#define"'s
#removes "*_MAX" and "*_CNT" lines because they does not contain values
defines="$( \
	cat ${FILE} | \
	perl -0777 -pe 's,/\*.*?\*/,,gs' | \
	sed -e 's/\t/ /g' | \
	sed 's/  */ /g' | \
	grep '#define' | \
	grep -v -e "_MAX " -e "_CNT " | \
	cut -d' ' -f2- | \
	remove_non_numbers \
)"

echo "/*"
echo " * DO NOT EDIT"
echo " * AUTOMATICALLY GENERATED BY $(basename $0)"
echo " */"
echo

tags=$(extract_tags)
for tag in $tags; do
	tag_defines="$(echo "$defines" | grep "^$tag")"
	codes="$( \
		echo "$tag_defines" | \
		awk '!seen[$2]++' | \
		cut -d' ' -f1 \
		)"

	echo "#define ${tag}_CODES \\"
	for code in $codes; do
		echo -e "\t x($code) \\"
	done
	echo
	
done
#extract_tags
#echo "$defines"

exit 0

remove_comments() {
	perl -0777 -pe 's,/\*.*?\*/,,gs' | \
	sed -e 's/\t/ /g' | \
	sed 's/  */ /g'
}

remove_unneded() {
	while read l; do
		name="$(echo $l | cut -d' ' -f1)"
		if ! [[ $name =~ "_MAX" ]]; then
			echo "$name"
		fi
	done
}

declare -A codes=()
defines="$( \
	cat ${FILE} | \
	remove_comments | \
	grep '#define' | \
	cut -d' ' -f2- | \
	remove_non_numbers | \
	sort -k2 | \
	remove_unneded
)"

echo "$defines"
exit 0

for tag in $tags; do
	while read -r l; do
		if [[ "$tag" == "$(echo $l | cut -d'_' -f1)" ]]; then
			codes[$tag]="${codes[$tag]} $l"
		fi
	done < <(echo "$defines")
done

echo "/*"
echo " * DO NOT EDIT"
echo " * AUTOMATICALLY GENERATED BY $(basename $0)"
echo " */"
echo

for tag in $tags; do
echo "#define ${tag}_CODES \\"
	for name in ${codes[$tag]}; do
		echo -e "\t x($name) \\"
	done
echo
done
		
