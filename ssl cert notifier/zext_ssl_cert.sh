#! /bin/sh
#------------------------------------------------------------
# zext_ssl_cert.sh
# Script checks for number of days until certificate expires or the issuing authority
# depending on switch passed on command line.
#
#Based on script from aperto.fr (http://aperto.fr/cms/en/blog/15-blog-en/15-ssl-certificate-expiration-monitoring-with-zabbix.html)
#with additions by racooper@tamu.edu
#Hivlaher additions for FreeBSD. Made the changes needed for the 
#date command so it works with FreeBSD date:)
#Also added a sed command to cut the " GMT" on the $end_date so
#it doesnt give an ignore error. So if your timezone is not GMT
#you may have to condider the Time difference :)
#------------------------------------------------------------

DEBUG=0
if [ $DEBUG -gt 0 ]
then
    exec 2>>/tmp/my.log
    set -x
fi

f=$1
host=$2
port=$3
sni=$4
proto=$5

if [ -z "$sni" ]
then
    servername=$host
else
    servername=$sni
fi

if [ -n "$proto" ]
then
    starttls="-starttls $proto"
fi

case $f in
-d)
end_date=`openssl s_client -servername $servername -host $host -port $port -showcerts $starttls -prexit </dev/null 2>/dev/null |
          sed -n '/BEGIN CERTIFICATE/,/END CERT/p' |
          openssl x509 -text 2>/dev/null |
          sed -n 's/ *Not After : *//p' |
          sed 's/ GMT//g'`

if [ -n "$end_date" ]
then
#    end_date_seconds=`date '+%s' --date "$end_date"`
    end_date_seconds=`date -j -f "%b %d %T %Y" "$end_date" "+%s"`
#    echo $end_date
    now_seconds=`date '+%s'`
#    echo $now_seconds
    echo "($end_date_seconds-$now_seconds)/24/3600" | bc
fi
;;

-i)
issue_dn=`openssl s_client -servername $servername -host $host -port $port -showcerts $starttls -prexit </dev/null 2>/dev/null |
          sed -n '/BEGIN CERTIFICATE/,/END CERT/p' |
          openssl x509 -text 2>/dev/null |
          sed -n 's/ *Issuer: *//p'`

if [ -n "$issue_dn" ]
then
    issuer=`echo $issue_dn | sed -n 's/.*CN=*//p'`
    echo $issuer
fi
;;
*)
echo "usage: $0 [-i|-d] hostname port sni"
echo "    -i Show Issuer"
echo "    -d Show valid days remaining"
;;
esac