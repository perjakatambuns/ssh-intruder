#!/bin/bash
#Filename: intruder_detect.sh
#Description: Check Linux Login History
id=$RANDOM
cp /var/log/auth.log /var/log/auth_"$id".log
cat /dev/null > /var/log/auth.log
AUTHLOG=/var/log/auth_"$id".log
URL=http://demo-dev.boyolali.go.id/tesaja/push.php
NAME=`hostname`
if [[ -n $1 ]];
then
  URL=$1
  echo Send To URL : $URL
fi

if [[ -n $2 ]];
then
  AUTHLOG=$2
  echo Using Log file : $AUTHLOG
fi

# Collect the failed login attempts
FAILED_LOG=/tmp/failed.$$.log
egrep "Failed pass" $AUTHLOG > $FAILED_LOG 

# Collect the successful login attempts
SUCCESS_LOG=/tmp/success.$$.log
egrep "Accepted password|Accepted publickey|keyboard-interactive" $AUTHLOG > $SUCCESS_LOG


# extract the users who failed
failed_users=$(cat $FAILED_LOG | awk '{ print $(NF-5) }' | sort | uniq)

# extract the users who successfully logged in
success_users=$(cat $SUCCESS_LOG | awk '{ print $(NF-5) }' | sort | uniq)
# extract the IP Addresses of successful and failed login attempts
failed_ip_list="$(egrep -o "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" $FAILED_LOG | sort | uniq)"
success_ip_list="$(egrep -o "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" $SUCCESS_LOG | sort | uniq)"
# Print the heading
printf "%-10s|%-10s|%-10s|%-10s|%-15s|%-15s|%s\n" "ID" "Status" "User" "Attempts" "IP address" "Host" "Time range"

# Loop through IPs and Users who failed.
for ip in $failed_ip_list;
do
  for user in $failed_users;
    do
    # Count failed login attempts by this user from this IP
    attempts=`grep $ip $FAILED_LOG | grep " $user " | wc -l`

    if [ $attempts -ne 0 ]
    then
      first_time=`grep $ip $FAILED_LOG | grep " $user " | head -1 | cut -c-16`
      date1=`echo "$first_time" | base64`
      time="$first_time"
      if [ $attempts -gt 1 ]
      then
        last_time=`grep $ip $FAILED_LOG | grep " $user " | tail -1 | cut -c-16`
        date2=`echo "$last_time" | base64`
        time="$first_time -> $last_time"
      fi
      HOST=$(host $ip 8.8.8.8 | tail -1 | awk '{ print $NF }' )
      hosts=`echo "$HOST" | base64`
      curl --get --url ""$URL"" \
           --data-urlencode "id="$id"" \
           --data-urlencode "node="$NAME"" \
           --data-urlencode "status=FAILED" \
           --data-urlencode "user="$user"" \
           --data-urlencode "count="$attempts"" \
           --data-urlencode "ip="$ip"" \
           --data-urlencode "resolve="$hosts"" \
           --data-urlencode "date1="$date1"" \
           --data-urlencode "date2="$date2""

      printf "%-10s|%-10s|%-10s|%-10s|%-15s|%-15s|%-s\n" "$id" "Failed" "$user" "$attempts" "$ip" "$HOST" "$time";
    fi
  done
done

for ip in $success_ip_list;
do
  for user in $success_users;
    do
    # Count successful login attempts by this user from this IP
    attempts=`grep $ip $SUCCESS_LOG | grep " $user " | wc -l`

    if [ $attempts -ne 0 ]
    then
      first_time=`grep $ip $SUCCESS_LOG | grep " $user " | head -1 | cut -c-16`
      date1=`echo "$first_time" | base64`
      time="$first_time"
      if [ $attempts -gt 1 ]
      then
        last_time=`grep $ip $SUCCESS_LOG | grep " $user " | tail -1 | cut -c-16`
        date2=`echo "$last_time" | base64`
        time="$first_time -> $last_time"
      fi
      HOST=$(host $ip 8.8.8.8 | tail -1 | awk '{ print $NF }' )
      hosts=`echo "$HOST" | base64`
      curl --get --url ""$URL"" \
           --data-urlencode "id="$id"" \
           --data-urlencode "node="$NAME"" \
           --data-urlencode "status=SUCCESS" \
           --data-urlencode "user="$user"" \
           --data-urlencode "count="$attempts"" \
           --data-urlencode "ip="$ip"" \
           --data-urlencode "resolve="$hosts"" \
           --data-urlencode "date1="$date1"" \
           --data-urlencode "date2="$date2""

      printf "%-10s|%-10s|%-10s|%-10s|%-15s|%-15s|%-s\n" "$id" "Success" "$user" "$attempts" "$ip" "$HOST" "$time";
    fi
  done
done

rm -f $FAILED_LOG
rm -f $SUCCESS_LOG
rm -f $AUTHLOG
