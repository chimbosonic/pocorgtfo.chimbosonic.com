#!/bin/bash

export pocorgtfo_mirror_url="https://www.alchemistowl.org/pocorgtfo"
export tmp_dir=$(mktemp -d)
export mirror_index="pocorgtfo_mirror_index.html"
export file_list="file_list.json"


function get_mirror_index() {
	wget ${pocorgtfo_mirror_url} -O ${tmp_dir}/${mirror_index}
}

function get_list_of_files() {
	grep "SHA256" ${tmp_dir}/${mirror_index} | while read -r file ;
	do
		file_name=$(echo $file | cut -d" " -f2 | tr -d "()" )
		file_hash=$(echo $file | cut -d" " -f4)
		jo filename=${file_name} sha256=${file_hash}
	done | jq --slurp . >  ${tmp_dir}/${file_list}

}

function get_pdfs() {
	#Generate a sha256sums file
	echo -n "" > sha256sums
	cat ${tmp_dir}/${file_list} | jq -c '.[]' | while read -r file ;
	do
		file_name=$(echo $file | jq -r .filename )
		file_hash=$(echo $file |  jq -r .sha256 )
		echo "${file_hash}  ${file_name}" >> sha256sums
	done

	cat ${tmp_dir}/${file_list} | jq -c '.[]' | while read -r file ;
	do
		file_name=$(echo $file | jq -r .filename )
		wget --no-clobber ${pocorgtfo_mirror_url}/${file_name} -O ${file_name}
	done 

	shasum -a 256 -c sha256sums
	rm sha256sums

	cat ${tmp_dir}/${file_list} | jq -c '.[]' | while read -r file ;
	do
		file_name=$(echo $file | jq -r .filename )
		file_hash=$(echo $file |  jq -r .sha256 )
		file_size=$(stat -c '%s' ${file_name} | numfmt --to=iec)
		jo filename=${file_name} sha256=${file_hash} size=${file_size}
	done | jq --slurp . > ${file_list}
}
get_mirror_index
get_list_of_files
get_pdfs