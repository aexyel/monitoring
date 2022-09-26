#!/bin/sh

##  /usr/lib/nagios/plugins/check_ups_eaton.sh
##  sh ./check_ups_eaton.sh -H 127.0.0.1 -C public

ST_OK=0
ST_WR=1
ST_CR=2
ST_UK=3

state=$ST_UK


## default host & community
comm=public
host=127.0.0.1


while [ -n "$1" ]
do
case "$1" in
-H) host=$2;;
-C) comm=$2;;
*) echo CRITICAL - Unknown option "$1 $2" && exit $ST_CR ;;
esac
shift
shift
done


val=`snmpget -v1 -Cf -c $comm $host mib-2.33.1.2.3.0 mib-2.33.1.2.4.0 mib-2.33.1.2.5.0 mib-2.33.1.3.3.1.2.1 mib-2.33.1.3.3.1.3.1 mib-2.33.1.4.2.0 mib-2.33.1.4.4.1.2.1 mib-2.33.1.4.4.1.3.1 mib-2.33.1.4.4.1.4.1 mib-2.33.1.4.4.1.5.1`

check=`echo $val | awk '{print $40 }'`
if [ "$check" = "" ];
    then echo "SNMP CRITICAL - No response ($host)" && exit $ST_CR
fi

output=`echo $val | awk '{print "In:" sprintf("%.1f",$16/10) "Hz,"$20 "V Out:" sprintf("%.1f",$24/10) "Hz,"$28 "V," sprintf("%.1f",$32/10) "A,load:"$36"W,"$40 "% Bat:"$4"min,chg:"$8"%," sprintf("%.1f",$12/10) "V" }'`

val1=`snmpget -v1 -Cf -c $comm $host mib-2.33.1.2.1.0 mib-2.33.1.4.1.0 mib-2.33.1.7.3.0`

check=`echo $val1 | awk '{print $12 }'`
if [ "$check" = "" ];
    then echo "SNMP CRITICAL - No status ($host) - $output" && exit $ST_CR
fi

output1=`echo $val1 | awk '{print " St:"$4","$8","$12}'`


battery_capacity=`echo $val | awk '{print $8}'`
output_load=`echo $val | awk '{print $40}'`
input_voltage=`echo $val | awk '{print $20}'`

if test $battery_capacity -lt 25
    then state=$ST_CR
         issue="BATTERY RUNNING LOW! "
elif test $output_load -gt 90
    then state=$ST_CR
         issue="HIGH OUTPUT LOAD! "
elif test $battery_capacity -lt 50
    then state=$ST_WR
         issue="BATTERY CAPACITY WARNING! "
elif test $input_voltage -lt 1
    then state=$ST_WR
         issue="RUNNING ON BATTERY! "
elif test $output_load -gt 80
    then state=$ST_WR
         issue="OUTPUT LOAD WARNING! "
else
    state=$ST_OK
fi


if test $state -eq $ST_OK
        then statestring="OK"
elif test $state -eq $ST_WR
        then statestring="WARNING"
elif test $state -eq $ST_CR
        then statestring="CRITICAL"
elif test $state -eq $ST_UK
        then statestring="UNKNOWN"
fi

echo "$statestring - $issue$output$output1"
exit $state
