#!/bin/bash
# set -x
config_file=config/subnet_info.txt
gateway_file=config/gateway_info.txt
template_file=config/netprobe.setup.template.xml
live_xml_file=config/netprobe_setup.xml

#Set variable defaults to LONDON UAT gateway.

REGION=LostandFound
COUNTRY=LostandFound
DATACENTER=LostandFound
REGION_CHANGE=LostandFound
PORT1=7038
PORT2=7048
PORT3=7058
PORT4=7068
PORT5=7078
PORT6=7088
PORT7=7098
PRIMARY_GATEWAY=ldc-lx-itrs03
SECONDARY_GATEWAY=ldn-lx-itrs03
ENVIRONMENT=UAT


cat $config_file | grep -v ^# | grep -v ^$ > $$_format.out

/sbin/ifconfig | grep "inet addr:" | sed 's/inet addr://g' |grep -v 127.0.0.1 | awk '{print $1}' > $$.out


#Tidy up input configuration file

while read lookup_info
do
	IP_SUBNET=`echo $lookup_info | sed s'/x.//g;s/x//g' | sed 's/\.$//g' | awk -F "," '{print $5}'`
	IP_SUBNET_LENGTH=`echo $lookup_info | sed s'/x.//g;s/x//g' | sed 's/\.$//g' | awk -F "," '{print $5}' | wc -m `
	IP_SUBNET_LENGTH_ACTUAL=`expr $IP_SUBNET_LENGTH - 1`

	if [ "$IP_SUBNET" == "`cat $$.out | cut -c1-$IP_SUBNET_LENGTH_ACTUAL`" ]
	then
		REGION=`echo $lookup_info | awk -F "," '{print $1}'`
		COUNTRY=`echo $lookup_info | awk -F "," '{print $2}'`
		DATACENTER=`echo $lookup_info | awk -F "," '{print $3}'`
		REGION_CHANGE=`grep $REGION $gateway_file | grep $ENVIRONMENT | awk -F"," '{print $2}'`
                PORT1=`grep $REGION $gateway_file | grep $ENVIRONMENT | awk -F"," '{print $6}'`
		PORT2=`grep $REGION $gateway_file | grep $ENVIRONMENT | awk -F"," '{print $7}'`
		PORT3=`grep $REGION $gateway_file | grep $ENVIRONMENT | awk -F"," '{print $8}'`
		PORT4=`grep $REGION $gateway_file | grep $ENVIRONMENT | awk -F"," '{print $9}'`
		PORT5=`grep $REGION $gateway_file | grep $ENVIRONMENT | awk -F"," '{print $10}'`
		PORT6=`grep $REGION $gateway_file | grep $ENVIRONMENT | awk -F"," '{print $11}'`
		PORT7=`grep $REGION $gateway_file | grep $ENVIRONMENT | awk -F"," '{print $12}'`
                PRIMARY_GATEWAY=`grep $REGION $gateway_file | grep $ENVIRONMENT | awk -F"," '{print $4}'`
                SECONDARY_GATEWAY=`grep $REGION $gateway_file | grep $ENVIRONMENT | awk -F"," '{print $5}'`
		break		
	fi

done < $$_format.out

# Create xml from template to live based on subnet

cat $template_file | sed -e "s/CHANGE_REGION_INFO/$REGION/g" \
			-e "s/CHANGE_DATACENTER_INFO/$DATACENTER/g" \
			-e "s/CHANGE_COUNTRY_INFO/$COUNTRY/g" \
			-e "s/REGION_CHANGE/$REGION_CHANGE/g" \
			-e "s/PRIMARY_GATEWAY/$PRIMARY_GATEWAY/g" \
			-e "s/SECONDARY_GATEWAY/$SECONDARY_GATEWAY/g" \
			-e "s/PORT1/$PORT1/g" \
			-e "s/PORT2/$PORT2/g" \
			-e "s/PORT3/$PORT3/g" \
			-e "s/PORT4/$PORT4/g" \
			-e "s/PORT5/$PORT5/g" \
			-e "s/PORT6/$PORT6/g" \
			-e "s/PORT7/$PORT7/g" \
			> $live_xml_file
			
	
#done < $$_format.out

rm $$.out
rm $$_format.out

exit 0

