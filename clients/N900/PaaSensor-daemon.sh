#!/bin/bash

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
  /usr/bin/gst-launch v4l2camsrc device=/dev/video0 num-buffers=1 \! video/x-raw-yuv,width=2592,height=1968  \! ffmpegcolorspace \! jpegenc \! filesink location=./current/$NOW.jpg
  echo "$NOW;$VAL1;$VAL2;$VAL3;$CELL_ID;$SIGNAL" >> current/data.list
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
