#!/bin/bash

source /home/sample/scripts/dataset.sh

hostname=$1
site=$2

function loading_time() {
	loadtime=$(curl -s -w '\nLookup Time:\t\t%{time_namelookup}\nConnect Time:\t\t%{time_connect}\nAppCon Time:\t\t%{time_appconnect}\nRedirect Time:\t\t%{time_redirect}\nPre-transfer Time:\t%{time_pretransfer}\nStart-transfer Time:\t%{time_starttransfer}\n\nTotal Time:\t\t%{time_total}\n' -o /dev/null https://$site/)

	lookup=$(echo "$loadtime" | sed -n '2p' | awk '{print $NF}')
	connect=$(echo "$loadtime" | sed -n '3p' | awk '{print $NF}')
	prexfer=$(echo "$loadtime" | sed -n '6p' | awk '{print $NF}')
	startxfer=$(echo "$loadtime" | sed -n '7p' | awk '{print $NF}')
	total=$(echo "$loadtime" | sed -n '$p' | awk '{print $NF}')
	tcheck=$(echo "$loadtime" | sed -n '$p' | awk '{print $NF*1000}')

	if [[ $tcheck -gt 5000 ]]; then
		header

		printf "%-20s %-15s %-15s %-15s %-15s %-15s\n" "$time" "$lookup" "$connect" "$prexfer" "$startxfer" "$total" >>$svrlogs/network/$hostname-loadtime_$date.txt

		send_mail

		if [[ $tcheck -gt 100000 ]]; then
			content=$(echo "Site not loading - $total sec load time - https://$site/")

			send_sms
		fi
	fi
}

function header() {
	if [ ! -f $svrlogs/network/$hostname-loadtime_$date.txt ]; then
		printf "%-20s %-15s %-15s %-15s %-15s %-15s\n" "DATE_TIME" "LOOKUP" "CONNECT" "PREXFER" "STARTXFER" "TOTAL" >>$svrlogs/network/$hostname-loadtime_$date.txt
	fi
}

function send_sms() {
	message=$(echo "$hostname: $content")

	php $scripts/send_sms.php "$message" "$validation"

	curl -X POST -H "Content-type: application/json" --data "{\"text\":\"$message\"}" $networkslack
}

function send_mail() {
	echo "SUBJECT: Load Time - $hostname - $(date +"%F %T")" >>$svrlogs/mail/ltmail_$time.txt
	echo "FROM: Load Time Check <root@$(hostname)>" >>$svrlogs/mail/ltmail_$time.txt
	echo "" >>$svrlogs/mail/ltmail_$time.txt
	printf "%-12s %20s\n" "DATE_TIME:" "$time" >>$svrlogs/mail/ltmail_$time.txt
	printf "%-12s %20s\n" "Lookup:" "$lookup" >>$svrlogs/mail/ltmail_$time.txt
	printf "%-12s %20s\n" "Connect:" "$connect" >>$svrlogs/mail/ltmail_$time.txt
	printf "%-12s %20s\n" "PreXfer:" "$prexfer" >>$svrlogs/mail/ltmail_$time.txt
	printf "%-12s %20s\n" "StartXfer:" "$startxfer" >>$svrlogs/mail/ltmail_$time.txt
	printf "%-12s %20s\n" "Total:" "$total" >>$svrlogs/mail/ltmail_$time.txt
	sendmail "$emailng" <$svrlogs/mail/ltmail_$time.txt
}

loading_time
