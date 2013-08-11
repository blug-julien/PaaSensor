#!/bin/bash

function acquireWifi {
  saveIFS=$IFS
  IFS=$'\n'
  sudo iwlist wlan0 scan  | grep -E 'Address|ESSID|Quality' > /tmp/paasensor.wifi
  READING="address"
  RESULT="["
  for line in `cat /tmp/paasensor.wifi`
  do
    if [ "$READING" == "address" ]; then
      MAC=`echo $line | cut -f2 -d'-' | cut -f3 -d' '`
      READING="ESSID"
    elif [ "$READING" == "ESSID" ]; then
      ESSID=`echo $line | cut -f2 -d'"'`
      READING="signal"
    elif [ "$READING" == "signal" ]; then
      SIGNAL=`echo $line | cut -f2 -d':' | cut -f1 -d' '`
      READING="address"
      RESULT="$RESULT{'mac':'$MAC','essid':'$ESSID','signal':$SIGNAL},"
    fi
  done
  RESULT="${RESULT%?}]"
  echo $RESULT
  IFS=$saveIFS
  #WIFI=`cat /tmp/paasensor.wifi | grep 'ESSID'`
  #echo $WIFI
  #arr=($WIFI)
  #echo ${arr[0]}
  #sudo iwlist wlan0 scan | awk -F '[ :=]+' '/(Address|ESSID|Signal Level)/{ printf $3" " } /Encr/{ print $4 }'
}

function acquireData {
  NOW=`date +"%Y%m%d%H%M%S"`
  SENSOR_VALUE=`cat /sys/class/i2c-adapter/i2c-3/3-001d/coord`
  VAL1=`echo $SENSOR_VALUE | cut -f1 -d' '`
  VAL2=`echo $SENSOR_VALUE | cut -f2 -d' '`
  VAL3=`echo $SENSOR_VALUE | cut -f3 -d' '`
  REG_STATUS=`dbus-send --system --print-reply --type=method_call --dest=com.nokia.phone.net /com/nokia/phone/net Phone.Net.get_registration_status`
  CELL_ID=`echo $REG_STATUS | cut -d' ' -f12`
  SIGNAL_STRENGTH=`dbus-send --system --print-reply --type=method_call --dest=com.nokia.phone.net /com/nokia/phone/net Phone.Net.get_signal_strength`
  SIGNAL=`echo $SIGNAL_STRENGTH | cut -d' ' -f10` 
  WIFI=`acquireWifi`
  #echo $WIFI
  /usr/bin/gst-launch v4l2camsrc device=/dev/video0 num-buffers=1 \! video/x-raw-yuv,width=2592,height=1968  \! ffmpegcolorspace \! jpegenc \! filesink location=./current/$NOW.jpg
  echo "$NOW;$VAL1;$VAL2;$VAL3;$CELL_ID;$SIGNAL;$WIFI" >> current/data.list
}

DELAY=$1
LIMIT=$2
i=2

acquireData

while [ $i -le $LIMIT ]
do
  sleep $DELAY; acquireData
  i=$(( $i + 1 ))
done
