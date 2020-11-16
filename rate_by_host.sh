DATA_INFLUX=""

FLAG_TS=1

# Execute rate command to get list of IPs and their current down/up rates, loop through results
rate -i re2 -r 5 -e -nl -Ab -a 255 -c 192.168.1.0/24 -d | while read -r line
do

   # Read the first character of this line
   FIRST_CHAR=`echo $line | head -c 1`

   # If the line starts with "-", then the run of rate is done, time to upload to influx
   if [ x"$FIRST_CHAR" == x"-" ]
   then 
      payload=`printf "$DATA_INFLUX"`

      curl -i -s -k -o /dev/null -XPOST "http://grafana:8086/write?db=site&precision=s&rp=site_7d_rp" --data-binary "$payload" 

      DATA_INFLUX=""
      FLAG_TS=1

   else
      # parse the output of rate
      hostip=`echo $line | cut -f1 -d":"`

      # use host command to get hostname based on ip
      host_name=`host $hostip` 

      # parse output of host command to get hostname, otherwise just use the IP
      if [ $? -eq 0 ]
      then
        thishost=`echo $host_name | cut -f5 -d" " | cut -f1 -d"."`

      else
        thishost=$hostip

      fi

      if [ $FLAG_TS -eq 1 ]; then
        ts=`date +%s`
        FLAG_TS=0
      fi

      thisdownload=`echo $line | cut -f4 -d":"`
      thisupload=`echo $line | cut -f5 -d":"`

      base_1="network_metric,host="
      base_2=",direction="
      base_3="byte_rate="
 
      DATA_INFLUX="$DATA_INFLUX"$base_1$thishost$base_2"download "$base_3$thisdownload" "$ts"\n"
      DATA_INFLUX="$DATA_INFLUX"$base_1$thishost$base_2"upload "$base_3$thisupload" "$ts"\n"

fi

done
