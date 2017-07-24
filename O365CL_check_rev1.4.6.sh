#!/bin/sh
########  Variables CONFIGURATION  #############################################
                                                                               #
                                                                               #
                                                                               #
### Thunder management IP
thunder_ip='localhost'
### Thunder login
user_name="admin"
password="a10"
#user_name="1234567890"
#password="1234567890abc"

### Timestamp
_DATE_TIME=$(date '+%Y_%m%d_%H%M')

###script exec time###
min_hours="00"
min_minutes="00"
max_hours="23"
max_minutes="58"


### class-list for o365 URLs ####################################################
                                                                                #

### class-list file name to be uploaded
class_list_name_o365="o365-url"
### class-list file name for archive
archive_cl_o365="archive_cl_o365-url"
### URL to get O365 XML file
url_xml="https://support.content.office.net/en-us/static/O365IPAddresses.xml"
### class-list match options "contains", "ends-with", "equals" or "starts-with"
match_options="contains"
### proxy_address
#proxy_address="https://10.10.10.10:8080"
proxy_address=

### class-list for IPv4/IPv6 ###################################################
                                                                               #

# "yes" to create class-list for IPv4 or IPv6, or "no"
get_ipv4="yes"
get_ipv6="yes"
### class-list file name to be uploaded
class_list_name_o365_ipv4="o365-ipv4"
class_list_name_o365_ipv6="o365-ipv6"
### class-list file name for archive
archive_cl_o365_ipv4="archive_cl_o365_ipv4"
archive_cl_o365_ipv6="archive_cl_o365_ipv6"

########  class-list for Skype for Business Online IPv4/IPv6 ###################
                                                                               #
# "yes" to create class-list for Skype IPv4 or IPv6, or "no"
get_skype_ipv4="yes"
get_skype_ipv6="yes"
get_skype_url="yes"
### class-list file name to be uploaded
class_list_name_skype_ipv4="skype-ipv4"
class_list_name_skype_ipv6="skype-ipv6"
class_list_name_skype_url="skype-url"
### class-list file name for archive
archive_cl_skype_ipv4="archive_cl_skype_ipv4"
archive_cl_skype_ipv6="archive_cl_skype_ipv6"
archive_cl_skype_url="archive_cl_skype_url"

### Directories ################################################################
                                                                               #
### For archives for class-list, xml and html
archive_dir="archive"
### For aXAPI json config files
conf_dir="conf"
                                                                               #
                                                                               #
########  Variables CONFIGURATION  #############################################

######## date time check #######################################################

let MIN="($min_hours * 60 + $min_minutes) * 60"
printf '%s\n' "$MIN"
let MAX="($max_hours * 60 + $max_minutes) * 60"
printf '%s\n' "$MAX"

date1=`date +%s`
echo $date1
date2=`expr $date1 + 32400`
NOW=`expr $date2 % 86400`
echo $NOW

if [ $NOW -ge $MIN -a $NOW -lt $MAX ]; then
	date '+%Y_%m%d_%H%M'
        echo "script is starting"
	/a10/bin/axlog -m 2 -p 6 O365CL_check_started
else
	date '+%Y_%m%d_%H%M'
        echo "out of time slot"
        exit
fi


########  Directory check  #####################################################
                                                                               #
cd `dirname $0` || exit 1
### if no file/directory exit, make them
if [[ ! -e /a10data/guest/${archive_dir} ]]; then
  mkdir /a10data/guest/${archive_dir}
fi
if [[ ! -e /a10data/guest/${conf_dir} ]]; then
  mkdir /a10data/guest/${conf_dir}
fi
if [[ ! -e /a10data/guest/tmp ]]; then
  mkdir /a10data/guest/tmp
fi
                                                                               #
########  Directory check  #####################################################

########  Get xml and Create class-list for o365 URLs ##########################
                                                                               #
                                                                               #                                                                               
result_code=0
### Rename xml file
xml_file=`echo $url_xml | sed -E 's/^.*\/(.*)$/\1/g'`
######## Verify o365 xml that HTTP response code is "200 OK" or not
export https_proxy=$proxy_address
if [[ `wget -nv --spider --timeout 60 -t 5 -O /a10data/guest/$xml_file $url_xml 2>&1 | grep '200 OK' -c` = "0" ]]; then
  ######## if failed, save the result of HTTP GET
  curl -k -v $url_xml
  /a10/bin/axlog -m 2 -p 6 o365 xml GET fail
  else
  ######## if 200OK, Get o365 xml file
  wget -O /a10data/guest/$xml_file $url_xml
  export https_proxy=
  ######## archive downloaded original xml file with timestamp
  mv -f /a10data/guest/$xml_file /a10data/guest/${archive_dir}/${archive_cl_o365}.xml
  ######## create class-list
  echo 'cat products/product[@name="o365"]/addresslist[@type="URL"]/address' | \
    xmllint --shell /a10data/guest/${archive_dir}/${archive_cl_o365}.xml | grep "<address>" | \
    sed -E 's/^.*(<address>(.*)<\/address>)$/\2/g' | \
    sed -E 's/^(.*\*\.|)(.*)$/\2/g' | \
    sed -E "s/^http.*:\/\///" | \
    grep '\.\*$' | \
    sed -E 's/^(.*)(\.\*)$/\1/g' | \
    sed -E "s/^/${match_options} /g" | \
    sed 's/\(\/\).*/\1/' | \
    sed 's/\///g' | \
　　tr A-Z a-z |sort |uniq >> /a10data/guest/${archive_dir}/${archive_cl_o365}.txt
  echo 'cat products/product[@name="o365"]/addresslist[@type="URL"]/address' | \
    xmllint --shell /a10data/guest/${archive_dir}/${archive_cl_o365}.xml | grep "<address>" | \
    sed -E 's/^.*(<address>(.*)<\/address>)$/\2/g' | \
    sed -E "s/^http.*:\/\///" | \
    grep -v '\.\*$' | \
    sed -E 's/^(.*\*\.|)(.*)$/\2/g' | \
    sed -E 's/(\*)//g' | \
    sed -E 's/(\s)//g' | \
    sed -E "s/^/${match_options} /g" | \
    sed 's/\(\/\).*/\1/' | \
    sed 's/\///g' | \
    tr A-Z a-z |sort |uniq > /a10data/guest/${archive_dir}/${archive_cl_o365}.txt
  sed -i -E "1i class-list $class_list_name_o365 ac file" /a10data/guest/${archive_dir}/${archive_cl_o365}.txt
    ######## copy and rename a new archive classlist to upload
    cp -f /a10data/guest/${archive_dir}/${archive_cl_o365}.txt /a10data/guest/$class_list_name_o365
    ######## check difference between downloaded file and current class-list file
     if diff -q /a10data/class-list/${class_list_name_o365} /a10data/guest/$class_list_name_o365 > /dev/null ; then
      ######## result: same file. no upload done
    echo "$class_list_name_o365 no update"
    else
      ######## aXAPI: Log in Thunder
      result=`curl -H "Accept-Encoding: identity" \
        -H "Content-type: application/json" \
        -d "{\"credentials\": {\"username\": \"$user_name\", \"password\": \"$password\"}}" \
        -k -s -X POST http://${thunder_ip}/axapi/v3/auth`
      auth_token=`echo $result | sed -E 's/^.*\"signature\":\"([0-9a-z]*)\".*$/\1/g'`
      ######## aXAPI: Import class-list
     echo "{\"class-list\":{\"action\":\"import\",\"file\":\"${class_list_name_o365}\",\"file-handle\":\"${class_list_name_o365}\"}}" > /a10data/guest/${conf_dir}/o365_all.json
      if [[ `curl -X POST -H "Accept-Encoding: identity" -H "Authorization: A10 ${auth_token}" \
       -F json=@/a10data/guest/$conf_dir/o365_all.json -F file=@/a10data/guest/$class_list_name_o365 \
       -k -vv http://${thunder_ip}/axapi/v3/file/class-list 2>&1 > importlog.txt | grep '200 OK' -c` = "1" ]]; then
      ######## output log message
      /a10/bin/axlog -m 2 -p 6 $class_list_name_o365 uploaded
      echo "$class_list_name_o365 uploaded"
      else
      /a10/bin/axlog -m 2 -p 6 $class_list_name_o365 upload failed
      echo "$class_list_name_o365 upload failed"
      fi
     ######## aXAPI: Log Off
      curl -H "Accept-Encoding: identity" \
       -H "Content-type: application/json" \
       -H "Authorization: A10 ${auth_token}" \
       -k -s \
       http://${thunder_ip}/axapi/v3/logoff > /dev/null
    fi
fi


                                                                               #
                                                                               #
                                                                               #
########  Get xml and Create class-list for o365 URL ###########################

########  Get xml and Create class-list for IPv4  ##############################
                                                                               #
                                                                               #
                                                                               #
######## Check if ipv4 is enabled
if [[ "$get_ipv4" = "yes" ]]; then
######## Check if XML file is successfully got
if [[ $result_code -ne 1 ]]; then
  ######## create class-list
  tmpfile1=$(mktemp)
  echo 'cat products/product[@name="o365"]/addresslist[@type="IPv4"]/address' | \
    xmllint --shell /a10data/guest/${archive_dir}/${archive_cl_o365}.xml  | grep "<address>" | \
    sed -E 's/^.*(<address>(.*)<\/address>)$/\2/g' | grep "/"  >> /a10data/guest${tmpfile1}
  echo 'cat products/product[@name="o365"]/addresslist[@type="IPv4"]/address' | \
    xmllint --shell /a10data/guest/${archive_dir}/${archive_cl_o365}.xml | grep "<address>" | \
    sed -E 's/^.*(<address>(.*)<\/address>)$/\2/g' | grep -v "/" | \
    sed -E 's/$/\/32/g' >> /a10data/guest${tmpfile1}
  cat /a10data/guest$tmpfile1 |sort |uniq > /a10data/guest/${archive_dir}/${archive_cl_o365_ipv4}.txt
  sed -i -E "1i class-list $class_list_name_o365_ipv4 ipv4 file" /a10data/guest/${archive_dir}/${archive_cl_o365_ipv4}.txt
  rm -f /a10data/guest$tmpfile1
    ######## copy and rename a new archive classlist to upload
    cp -f /a10data/guest/${archive_dir}/${archive_cl_o365_ipv4}.txt /a10data/guest/$class_list_name_o365_ipv4
    ######## check difference between downloaded file and current class-list file
    if diff -q /a10data/class-list/${class_list_name_o365_ipv4} /a10data/guest/$class_list_name_o365_ipv4 > /dev/null ; then
      ######## result: same file. no upload done
      echo "$class_list_name_o365_ipv4 no update"
    else
      ######## aXAPI: Log in Thunder
      result=`curl -H "Accept-Encoding: identity" \
        -H "Content-type: application/json" \
        -d "{\"credentials\": {\"username\": \"$user_name\", \"password\": \"$password\"}}" \
        -k -s -X POST http://${thunder_ip}/axapi/v3/auth`
      auth_token=`echo $result | sed -E 's/^.*\"signature\":\"([0-9a-z]*)\".*$/\1/g'`
      ######## aXAPI: Import class-list
      echo "{\"class-list\":{\"action\":\"import\",\"file\":\"${class_list_name_o365_ipv4}\",\"file-handle\":\"${class_list_name_o365_ipv4}\"}}" > /a10data/guest/${conf_dir}/o365_o365_ipv4.json
      if [[ `curl -X POST -H "Accept-Encoding: identity" -H "Authorization: A10 ${auth_token}" \
       -F json=@/a10data/guest/${conf_dir}/o365_o365_ipv4.json -F file=@/a10data/guest/${class_list_name_o365_ipv4} \
       -k -vv http://${thunder_ip}/axapi/v3/file/class-list 2>&1 | grep "200 OK" -c` = "1" ]]; then
      ######## output log message
      /a10/bin/axlog -m 2 -p 6 $class_list_name_o365_ipv4 uploaded
      echo "$class_list_name_o365_ipv4 uploaded"
      else
      /a10/bin/axlog -m 2 -p 6 $class_list_name_o365_ipv4 upload failed
      echo "$class_list_name_o365_ipv4 upload failed"
      fi
      ######## aXAPI: Log Off
      curl -H "Accept-Encoding: identity" \
       -H "Content-type: application/json" \
       -H "Authorization: A10 ${auth_token}" \
       -k -s \
       http://${thunder_ip}/axapi/v3/logoff > /dev/null
    fi
fi
fi
                                                                               #
                                                                               #
                                                                               #
########  Get xml and Create class-list for IPv4  ##############################

########  Get xml and Create class-list for IPv6  ##############################
                                                                               #
                                                                               #
                                                                               #
######## Check if ipv6 is enabled
if [[ "$get_ipv6" = "yes" ]]; then
######## Check if XML file is successfully got
if [[ $result_code -ne 1 ]]; then
  tmpfile1=$(mktemp)
  ######## create class-list
  echo 'cat products/product[@name="o365"]/addresslist[@type="IPv6"]/address' | \
    xmllint --shell /a10data/guest/${archive_dir}/${archive_cl_o365}.xml  | grep "<address>" | \
    sed -E 's/^.*(<address>(.*)<\/address>)$/\2/g' | grep "/"  >> /a10data/guest${tmpfile1}
  echo 'cat products/product[@name="o365"]/addresslist[@type="IPv6"]/address' | \
    xmllint --shell /a10data/guest/${archive_dir}/${archive_cl_o365}.xml | grep "<address>" | \
    sed -E 's/^.*(<address>(.*)<\/address>)$/\2/g' | grep -v "/" | \
    sed -E 's/$/\/128/g' >> /a10data/guest${tmpfile1}
  cat /a10data/guest$tmpfile1 |sort |uniq > /a10data/guest/${archive_dir}/${archive_cl_o365_ipv6}.txt
  sed -i -E "1i class-list $class_list_name_o365_ipv6 ipv6 file" /a10data/guest/${archive_dir}/${archive_cl_o365_ipv6}.txt
  rm -f /a10data/guest$tmpfile1
    ######## copy and rename a new archive classlist to upload
    cp -f /a10data/guest/${archive_dir}/${archive_cl_o365_ipv6}.txt /a10data/guest/$class_list_name_o365_ipv6
    ######## check difference between downloaded file and current class-list file
    if diff -q /a10data/class-list/${class_list_name_o365_ipv6} /a10data/guest/${class_list_name_o365_ipv6} > /dev/null ; then
      ######## result: same file. no upload done
      echo "${class_list_name_o365_ipv6} no update"
    else
      ######## aXAPI: Log in Thunder
      result=`curl -H "Accept-Encoding: identity" \
        -H "Content-type: application/json" \
        -d "{\"credentials\": {\"username\": \"$user_name\", \"password\": \"$password\"}}" \
        -k -s -X POST http://${thunder_ip}/axapi/v3/auth`
      auth_token=`echo $result | sed -E 's/^.*\"signature\":\"([0-9a-z]*)\".*$/\1/g'`
      ######## aXAPI: Import class-list
      echo "{\"class-list\":{\"action\":\"import\",\"file\":\"${class_list_name_o365_ipv6}\",\"file-handle\":\"${class_list_name_o365_ipv6}\"}}" > /a10data/guest/${conf_dir}/o365_o365_ipv6.json
      if [[ `curl -X POST -H "Accept-Encoding: identity" -H "Authorization: A10 ${auth_token}" \
       -F json=@/a10data/guest/${conf_dir}/o365_o365_ipv6.json -F file=@/a10data/guest/${class_list_name_o365_ipv6} \
       -k -vv http://${thunder_ip}/axapi/v3/file/class-list 2>&1 | grep "200 OK" -c` = "1" ]]; then
      ######## output log message
      /a10/bin/axlog -m 2 -p 6 $class_list_name_o365_ipv6 uploaded
      echo "$class_list_name_o365_ipv6 uploaded"
      else
      /a10/bin/axlog -m 2 -p 6 $class_list_name_o365_ipv6 upload failed
      echo "$class_list_name_o365_ipv6 upload failed"
      fi
      ######## aXAPI: Log Off
      curl -H "Accept-Encoding: identity" \
       -H "Content-type: application/json" \
       -H "Authorization: A10 ${auth_token}" \
       -k -s \
       http://${thunder_ip}/axapi/v3/logoff > /dev/null
    fi
fi
fi


                                                                               #
                                                                               #
                                                                               #
########  Get xml and Create class-list for IPv6  ##############################

########  Create class-list for Skype for Business Online IPv4 #################
                                                                               #
                                                                               #
                                                                               #
                                                                               
######## Check if ipv4 is enabled
if [[ "$get_skype_ipv4" = "yes" ]]; then
######## Check if XML file is successfully got
if [[ $result_code -ne 1 ]]; then
  ######## create class-list
  tmpfile1=$(mktemp)
  echo 'cat products/product[@name="LYO"]/addresslist[@type="IPv4"]/address' | \
    xmllint --shell /a10data/guest/${archive_dir}/${archive_cl_o365}.xml  | grep "<address>" | \
    sed -E 's/^.*(<address>(.*)<\/address>)$/\2/g' | grep "/"  >> /a10data/guest${tmpfile1}
  echo 'cat products/product[@name="LYO"]/addresslist[@type="IPv4"]/address' | \
    xmllint --shell /a10data/guest/${archive_dir}/${archive_cl_o365}.xml | grep "<address>" | \
    sed -E 's/^.*(<address>(.*)<\/address>)$/\2/g' | grep -v "/" | \
    sed -E 's/$/\/32/g' >> /a10data/guest${tmpfile1}
  cat /a10data/guest$tmpfile1 |sort |uniq > /a10data/guest/${archive_dir}/${archive_cl_skype_ipv4}.txt
  sed -i -E "1i class-list $class_list_name_skype_ipv4 ipv4 file" /a10data/guest/${archive_dir}/${archive_cl_skype_ipv4}.txt
  rm -f /a10data/guest$tmpfile1
    ######## copy and rename a new archive classlist to upload
    cp -f /a10data/guest/${archive_dir}/${archive_cl_skype_ipv4}.txt /a10data/guest/$class_list_name_skype_ipv4
    ######## check difference between downloaded file and current class-list file
    if diff -q /a10data/class-list/${class_list_name_skype_ipv4} /a10data/guest/${class_list_name_skype_ipv4} > /dev/null ; then
      ######## result: same file. no upload done
      echo "${class_list_name_skype_ipv4} no update"
    else
      ######## aXAPI: Log in Thunder
      result=`curl -H "Accept-Encoding: identity" \
        -H "Content-type: application/json" \
        -d "{\"credentials\": {\"username\": \"$user_name\", \"password\": \"$password\"}}" \
        -k -s -X POST http://${thunder_ip}/axapi/v3/auth`
      auth_token=`echo $result | sed -E 's/^.*\"signature\":\"([0-9a-z]*)\".*$/\1/g'`
      ######## aXAPI: Import class-list
      echo "{\"class-list\":{\"action\":\"import\",\"file\":\"${class_list_name_skype_ipv4}\",\"file-handle\":\"${class_list_name_skype_ipv4}\"}}" > /a10data/guest/${conf_dir}/o365_skype_ipv4.json
      if [[ `curl -X POST -H "Accept-Encoding: identity" -H "Authorization: A10 ${auth_token}" \
       -F json=@/a10data/guest/${conf_dir}/o365_skype_ipv4.json -F file=@/a10data/guest/${class_list_name_skype_ipv4} \
       -k -vv http://${thunder_ip}/axapi/v3/file/class-list 2>&1 | grep "200 OK" -c` = "1" ]]; then
      ######## output log message
      /a10/bin/axlog -m 2 -p 6 $class_list_name_skype_ipv4 uploaded
      echo "$class_list_name_skype_ipv4 uploaded"
      else
      /a10/bin/axlog -m 2 -p 6 $class_list_name_skype_ipv4 upload failed
      echo "$class_list_name_skype_ipv4 upload failed"
      fi
      ######## aXAPI: Log Off
      curl -H "Accept-Encoding: identity" \
       -H "Content-type: application/json" \
       -H "Authorization: A10 ${auth_token}" \
       -k -s \
       http://${thunder_ip}/axapi/v3/logoff > /dev/null
    fi
fi
fi


                                                                               #
                                                                               #
                                                                               #
########  Create class-list for Skype for Business Online IPv4 #################

########  Create class-list for Skype for Business Online IPv6 #################
                                                                               #
                                                                               #
                                                                               #
######## Check if ipv6 is enabled
if [[ "$get_skype_ipv6" = "yes" ]]; then
######## Check if XML file is successfully got
if [[ $result_code -ne 1 ]]; then
  tmpfile1=$(mktemp)
  ######## create class-list
  echo 'cat products/product[@name="LYO"]/addresslist[@type="IPv6"]/address' | \
    xmllint --shell /a10data/guest/${archive_dir}/${archive_cl_o365}.xml  | grep "<address>" | \
    sed -E 's/^.*(<address>(.*)<\/address>)$/\2/g' | grep "/"  >> /a10data/guest${tmpfile1}
  echo 'cat products/product[@name="LYO"]/addresslist[@type="IPv6"]/address' | \
    xmllint --shell /a10data/guest/${archive_dir}/${archive_cl_o365}.xml | grep "<address>" | \
    sed -E 's/^.*(<address>(.*)<\/address>)$/\2/g' | grep -v "/" | \
    sed -E 's/$/\/128/g' >> /a10data/guest${tmpfile1}
  cat /a10data/guest$tmpfile1 |sort |uniq > /a10data/guest/${archive_dir}/${archive_cl_skype_ipv6}.txt
  sed -i -E "1i class-list $class_list_name_skype_ipv6 ipv6 file" /a10data/guest/${archive_dir}/${archive_cl_skype_ipv6}.txt
  rm -f /a10data/guest$tmpfile1
    ######## copy and rename a new archive classlist to upload
    cp -f /a10data/guest/${archive_dir}/${archive_cl_skype_ipv6}.txt /a10data/guest/$class_list_name_skype_ipv6
    ######## check difference between downloaded file and current class-list file
    if diff -q /a10data/class-list/${class_list_name_skype_ipv6} /a10data/guest/${class_list_name_skype_ipv6} > /dev/null ; then
      ######## result: same file. no upload done
      echo "${class_list_name_skype_ipv6} no update"
    else
      ######## aXAPI: Log in Thunder
      result=`curl -H "Accept-Encoding: identity" \
        -H "Content-type: application/json" \
        -d "{\"credentials\": {\"username\": \"$user_name\", \"password\": \"$password\"}}" \
        -k -s -X POST http://${thunder_ip}/axapi/v3/auth`
      auth_token=`echo $result | sed -E 's/^.*\"signature\":\"([0-9a-z]*)\".*$/\1/g'`
      ######## aXAPI: Import class-list
      if [[ `echo "{\"class-list\":{\"action\":\"import\",\"file\":\"${class_list_name_skype_ipv6}\",\"file-handle\":\"${class_list_name_skype_ipv6}\"}}" > /a10data/guest/${conf_dir}/o365_o365_ipv6.json
      curl -X POST -H "Accept-Encoding: identity" -H "Authorization: A10 ${auth_token}" \
       -F json=@/a10data/guest/${conf_dir}/o365_o365_ipv6.json -F file=@/a10data/guest/${class_list_name_skype_ipv6} \
       -k -vv http://${thunder_ip}/axapi/v3/file/class-list 2>&1 | grep "200 OK" -c` = "1" ]]; then
      ######## output log message
      /a10/bin/axlog -m 2 -p 6 $class_list_name_skype_ipv6 uploaded
      echo "$class_list_name_skype_ipv6 uploaded"
      else
      /a10/bin/axlog -m 2 -p 6 $class_list_name_skype_ipv6 upload failed
      echo "$class_list_name_skype_ipv6 upload failed"
      fi
      ######## aXAPI: Log Off
      curl -H "Accept-Encoding: identity" \
       -H "Content-type: application/json" \
       -H "Authorization: A10 ${auth_token}" \
       -k -s \
       http://${thunder_ip}/axapi/v3/logoff > /dev/null
    fi
fi
fi


                                                                               #
                                                                               #
                                                                               #
########  Create class-list for Skype for Business Online IPv6  ################

########  Create class-list for Skype for Business Online URLs #################
                                                                               #
                                                                               #
                                                                               #
######## Check if skype_url is enabled
if [[ "$get_skype_url" = "yes" ]]; then
######## Check if XML file is successfully got
if [[ $result_code -ne 1 ]]; then
  ######## create class-list
  result_code_skype_url=0
  echo 'cat products/product[@name="LYO"]/addresslist[@type="URL"]/address' | \
    xmllint --shell /a10data/guest/${archive_dir}/${archive_cl_o365}.xml  | grep "<address>" | \
    sed -E 's/^.*(<address>(.*)<\/address>)$/\2/g' | \
    sed -E 's/^(.*\*\.|)(.*)$/\2/g' | \
    sed -E "s/^http.*:\/\///" | \
    grep '\.\*$' | \
    sed -E 's/^(.*)(\.\*)$/\1/g' | \
    sed -E "s/^/${match_options} /g" | \
　　tr A-Z a-z |sort |uniq >> /a10data/guest/${archive_dir}/${archive_cl_skype_url}.txt
  echo 'cat products/product[@name="LYO"]/addresslist[@type="URL"]/address' | \
    xmllint --shell /a10data/guest/${archive_dir}/${archive_cl_o365}.xml  | grep "<address>" | \
    sed -E 's/^.*(<address>(.*)<\/address>)$/\2/g' | \
    sed -E "s/^http.*:\/\///" | \
    grep -v '\.\*$' | \
    sed -E 's/^(.*\*\.|)(.*)$/\2/g' | \
    sed -E 's/(\*)//g' | \
    sed -E 's/(\s)//g' | \
    sed -E "s/^/${match_options} /g" | \
    tr A-Z a-z |sort |uniq > /a10data/guest/${archive_dir}/${archive_cl_skype_url}.txt
  sed -i -E "1i class-list $class_list_name_skype_url ac file" /a10data/guest/${archive_dir}/${archive_cl_skype_url}.txt

    ######## copy and rename a new archive classlist to upload
    cp -f /a10data/guest/${archive_dir}/${archive_cl_skype_url}.txt /a10data/guest/${class_list_name_skype_url}
    ######## check difference between downloaded file and current class-list file
     if diff -q /a10data/class-list/${class_list_name_skype_url} /a10data/guest/${class_list_name_skype_url} > /dev/null ; then
      ######## result: same file. no upload done
      echo "$class_list_name_o365 no update"
      else
      ######## aXAPI: Log in Thunder
      result=`curl -H "Accept-Encoding: identity" \
        -H "Content-type: application/json" \
        -d "{\"credentials\": {\"username\": \"$user_name\", \"password\": \"$password\"}}" \
        -k -s -X POST http://${thunder_ip}/axapi/v3/auth`
      auth_token=`echo $result | sed -E 's/^.*\"signature\":\"([0-9a-z]*)\".*$/\1/g'`
      ######## aXAPI: Import class-list
      echo "{\"class-list\":{\"action\":\"import\",\"file\":\"${class_list_name_skype_url}\",\"file-handle\":\"${class_list_name_skype_url}\"}}" > /a10data/guest/${conf_dir}/o365_skype_url.json
      if [[ `curl -X POST -H "Accept-Encoding: identity" -H "Authorization: A10 ${auth_token}" \
       -F json=@/a10data/guest/$conf_dir/o365_skype_url.json -F file=@/a10data/guest/${class_list_name_skype_url} \
       -k -vv http://${thunder_ip}/axapi/v3/file/class-list 2>&1 > importlog.txt | grep '200 OK' -c` = "1" ]]; then
      ######## output log message
      /a10/bin/axlog -m 2 -p 6 $class_list_name_skype_url uploaded
      echo "$class_list_name_skype_url uploaded"
      else
      /a10/bin/axlog -m 2 -p 6 $class_list_name_skype_url upload failed
      echo "$class_list_name_skype_url upload failed"
      fi
      ######## aXAPI: Log Off
      curl -H "Accept-Encoding: identity" \
       -H "Content-type: application/json" \
       -H "Authorization: A10 ${auth_token}" \
       -k -s \
       http://${thunder_ip}/axapi/v3/logoff > /dev/null
    fi
  fi
fi
fi
                                                                               #
                                                                               #
                                                                               #
########  Create class-list for Skype for Business Online URL  #################
exit 0


