#!/bin/bash

# If % disk space of filesystem (option f) greater than the limit (option l), 
# send email to email (to email address provided by option m)
# If filesystem (e.g. /dev/xvda, /dev/sda5, etc) not provided to the script, it will take the first one from df -h
# you can also pass the email subject to the script using script using -s option. Don't forget to quote that argument

usage() { echo -e "${YELLOW}Usage: $0 -l <%limit> [-f <filesystem>] [-m <email>] [-s <quoted-email-subject>]${NC}" 1>&2; exit 1; }

create_email_content() {
    content='<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
	     <html>
	     <head><title></title>
	     </head>
	     <body>
	     <p>'"$1"'</p>
	     </body>
	     </html>'
    echo $content
}

send_email() {
    (
        echo "From: $3"
        echo "To: $4"
        echo "Subject: $2"
        echo "Content-Type: text/html"
        echo
        create_email_content "$1"
        echo
    ) | sendmail -t -v
}

RED='\033[0;31m'
YELLOW='\e[0;33m'
BLUE='\e[0;34m'
GREEN='\e[0;32m'
NC='\033[0m' # No Color
MAILTO='to@domain.com'
MAILFROM='from@domain.com'

# -l is required
# -f and -m are optional
while getopts "l:f::m::s::" o; do
    case "${o}" in
        l)
            l=${OPTARG}
            ;;
        f)
            f=${OPTARG}
            ;;
        m) 
            m=${OPTARG}
            ;;
        s)
            s=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

# as -l is required, redir to usage when not provided
if [ -z ${l+x} ]; then
    usage
fi
limit=$l

filesystem=""
if [[ ! -z ${f+x} ]]; then
    filesystem=$f
fi

mailto=MAILTO
if [[ ! -z ${m+x} ]]; then
    mailto=$m
fi

report=`df -H | tail -n+2 | grep "$filesystem" | head -1`

# filesystem not found in df, report will be empty => throw error and exit
if [ -z "$report" ]; then
    echo -e "${RED}Unrecognized filesystem=$filesystem. Specify any of the following${NC}"
    echo -e "${YELLOW}"
    df -H | tail -n+2 | awk '{print $1}'
    echo -e "${NC}"
    exit 1
fi

if [[ $limit -gt 0 && $limit -lt 100 ]]; then 
    # filesystem and limit valid
    diskspace=`echo $report | awk '{print $5}' | cut -d'%' -f1`   # disk space in %
    remain=`echo $report | awk '{print $4 "("$2"-"$3")"}'`

    # prepare to send an email
    body="$HOSTNAME : disk space="$diskspace"%, remaining="$remain
    # default subject
    subject="$HOSTNAME is running out of disk space. Used=$diskspace%"
    echo $body
    # optional subject provided by -s option
    if [[ ! -z ${s+x} ]]; then
        subject=${s}
    fi   
    # % Disk usage has exceeded the limit
    if [ $diskspace -ge $limit ]; then
        # send email
        echo -e "${GREEN}sending email ...${NC}"
        send_email "$body" "$subject" $MAILFROM $mailto
    else
        echo -e "${BLUE}Disk usage is < limit($limit%). No need to notify ...${NC}"
    fi
else
     # valid limit = (0..100). For invalid limit => throw error and exit
     echo -e "${RED}Invalid limit ($limit). It should range from 0 to 100.${NC}"
     exit 1
fi
