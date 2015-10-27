#!/bin/sh
tmpdir="/tmp/responsecount"
file="/var/log/nginx/access.log"
response_time="5.0"
count="3"
#---------------------------
STATE_UK=3
#----------------------------
PROGNAME=`basename $0`
print_help() {
    echo ""
    echo "prerequisite:"
    echo "Please update in the nginx configuration file to log the request_time"
    echo "Define the custom logging in the nginx configuration file and request_time is taken as the last field in log file"
    echo "Description:"
    echo "This script is a Nagios plugin to check the response time from the access.log file."
    echo "Example call:"
    echo "./$PROGNAME -d /tmp/responsecount -f /var/log/nginx/access.log -t 5.0 -c 3 "
    echo ""
    echo "Options:"
    echo "  -d|--tempdir"
    echo "    Sets a the directory where the script store all the processing files. default is:/tmp/responsecount "
    echo "  -f|--file"
    echo "    Sets a log file to chcek the error. default is:/var/log/nginx/access.log "
    echo "  -t|--response_time"
    echo "    Specify the response time value for which you want to compare against your response time in access.log file. default is:5.0 "
    echo "  -c|--count"
    echo "    Specify the count, where in if the number occurrences of  response_time is greater than the “Count” the opsview  triggers an alarm. default is:3 "
exit $STATE_UK
}
#----------------------------
# Make sure the correct number of command line
# arguments have been supplied

if [ $# -lt 1 ]; then
    echo "Please the arguments: ''"
    print_help
    exit $STATE_UK
fi
#---------------------------
while test -n "$1"; do
case "$1" in
        --help|-h)
                print_help
                exit $STATE_UK
                ;;
        --tempdir|-d)
                tmpdir=$2
                shift
                ;;
        --file|-f)
                file=$2
                shift
                ;;
        --response_time|-t)
                response_time=$2
                shift
                ;;
        --count|-c)
                count=$2
                shift
                ;;
        *)
                echo "Unknown argument: $1"
          print_help
          exit $STATE_UK
          ;;
        esac
        shift
done
#----------------------------
#echo $tmpdir
#echo $file
#echo $response_time
#echo $count
#-----------------------------
responsestatus=$tmpdir/responsestatus
echo $responsestatus
date=`date "+%Y%m%d-%H:%M:%S"`
j=0
#-------Creating directory for processing--
ls $tmpdir >> /dev/null 2>&1
if [ `echo $?` -ne 0 ]
then
mkdir $tmpdir
fi
#--------checking the seeking file----
ls $responsestatus >> /dev/null 2>&1
if [ `echo $?` -ne 0 ]
then
echo 1 > $responsestatus
fi
#-----------Actual Logic-----------------
countpresent=`wc -l $file | awk '{print $1}'`
countold=`cat $responsestatus`
sed -n "$countold","$countpresent"p $file | awk  '{print $NF}' | grep ^[0-9] >> $tmpdir/responsefile-$date
for i in `cat $tmpdir/responsefile-$date`
do
#time_secs=`echo "scale=2;${i}/1000" |bc`
#echo $time_secs                                #miisecs to sec convertion
if [ `echo "$i > $response_time" | bc` -gt 0 ]
then
j=`expr $j + 1`
#echo $j
fi
done
sed -i 's/'$countold'/'$countpresent'/g' $responsestatus
#--- OPSVIEW ALERTING---------------------
if [ $j -gt $count ]
then
echo "Error count greater that 3, check $tmpdir/responsefile-$date "
exit 2
else
echo "OK, check $tmpdir/responsefile-$date"
exit 0
fi
