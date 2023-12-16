#!/bin/bash

source /home/sample/scripts/dataset.sh

sec=5

function loadtime_check() {
	data=($(cat $scripts/network/ip.txt))
	count=${#data[@]}

	for ((i = 0; i < count; i = i + 2)); do
		ip=$(echo "${data[i]}")
		svrhost=$(host $ip | awk '{print $NF}' | awk -F'.' '{print $1}')
		site=$(echo "${data[i + 1]}")

		sh $scripts/network/loadtime.sh $svrhost $site

		sleep $sec

	done
}

loadtime_check
