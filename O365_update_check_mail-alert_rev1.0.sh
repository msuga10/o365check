#!/bin/sh
########  Variables CONFIGURATION  #############################################
                                                                               #
                                                                               #
                                                                               #
### Thunder management IP
#thunder_ip='172.31.255.52'
### Timestamp
_DATE_TIME=$(date '+%Y_%m%d_%H%M')

### class-list for ALL URLs ####################################################
                                                                               #
### slb template policy name to apply Explicit Proxy feature
temp_pol_name="cp1"
### source name under slb template policy to apply class-list for ALL URLs as destination
source_name_all="source_all"
### class-list file name to be uploaded
class_list_name_all="all-url"
### class-list file name for archive
archive_cl_all="${_DATE_TIME}_all-url"
### URL to get O365 XML file
url_xml="https://support.content.office.net/en-us/static/O365IPAddresses.xml"
### log file name to be created when url is failed to retrieve
err_curl_xml_log="err_curl_xml_for_all_urls_${_DATE_TIME}.txt"
### log file name to be created when there is difference in class-list of all URLs 
diff_result_all="diff_${archive_cl_all}.txt"
### log file name to be created when there is difference in XMLs files 
diff_result_xml="diff_xml_${_DATE_TIME}.txt"

### class-list for CLR URLs ####################################################
                                                                               #
### class-list file name to be uploaded
class_list_name_crl="crl-url"
### class-list file name for archive
archive_cl_crl="${_DATE_TIME}_crl-url"
### log file name to be created when there is difference in class-list of all URLs
diff_result_crl="diff_${archive_cl_crl}.txt"

### class-list for noCLR URLs ##################################################
                                                                               #
### class-list file name to be uploaded
class_list_name_nocrl="nocrl-url"
### class-list file name for archive
archive_cl_nocrl="${_DATE_TIME}_nocrl-url"
### log file name to be created when there is difference in class-list of all URLs
diff_result_nocrl="diff_${archive_cl_nocrl}.txt"

### class-list for IPv4/IPv6 ###################################################
                                                                               #
# "yes" to create class-list for IPv4 or IPv6, or "no"
get_ipv4="yes"
get_ipv6="yes"
### class-list file name to be uploaded
class_list_name_all_ipv4="all-ipv4"
class_list_name_all_ipv6="all-ipv6"
### class-list file name for archive
archive_cl_all_ipv4="${_DATE_TIME}_all_ipv4"
archive_cl_all_ipv6="${_DATE_TIME}_all_ipv6"
### log file name to be created when there is difference in IP addresses
diff_result_all_ipv4="diff_${archive_cl_all_ipv4}.txt"
diff_result_all_ipv6="diff_${archive_cl_all_ipv6}.txt"


### E-mail setting #############################################################
                                                                               #
mail_from_ad="Office365@a10kk.com"
mail_from_name="A10 O365 class-list builder"
#mail_to="mssuga.772805@gmail.com"
mail_to="msuga@a10networks.com"

### E-mail message body - header ###############################################
mail_message="\
++++++++++++++++++++++++++++++\n\
A10 Office365 URL class-list builder\n\
Script file: $(basename ${0})\n\
Executed time: $_DATE_TIME\n\
Thunder IP address: $thunder_ip\n\
++++++++++++++++++++++++++++++\n"

mail_all_url_message="\n\
+++ class-list for all URLs +++\n"

### E-mail message body if failed to get XML file ##############################
mail_1="\
Failed to get O365 URL list page. \nXMLファイルの取得に失敗しました\n\
Please check log 添付ログを確認してください: \n\
${err_curl_html_log}\n"
### E-mail message body if XML file is not updated #############################
mail_2="\
No update. 変更はありません\n\
"
### E-mail message body if XML file is updated (there is difference between  ###
### newly uploaded file and last-uploaded file)                              ###
mail_3="\
O365 class-list file for all URLs is uploaded. \n\
全URL class-listファイルに更新がありclass-listをアップロードしました\n\
Uploaded file: ${archive_cl_all}.txt\n\
diff result: ${diff_result_all} \n\
Uploaded file: ${archive_cl_nocrl}.txt\n\
diff result: ${diff_result_nocrl} \n\
"
### E-mail message body if a created class-list is empty ###
mail_4="\
Uploading class-list is canseled since a created class-list is empty.\n\
Please check the XML page and the class-list\n\
生成されたclass-listが空であるためアップロードを中止しました。XMLファイルを確認してください\n\
Updated file: ${archive_cl_all}.txt\n\
URL: $url_xml \n\
"
mail_character_validation_message="\n\
+++ character validation for URL +++\n"

### E-mail message body if invalid characters in noCRL list ###
mail_5="\
Invalid character was founded in noCRL list.\n\
URLの表記ポリシーが変更された可能性があります。Class-listを確認ください\n\
file: nocrl_invalid.txt\n\
"
### E-mail message body if no invalid characters in noCRL list ###
mail_6="\
Invalid character was not founded in noCRL list.\n\
URL表記に問題はありません\n\
"
### E-mail message body if IPv4 class-list ####################################
mail_ipv4_message="\n\
+++ class-list for IPv4 +++\n"
### E-mail message body if IPV4 addresses is not updated ###
mail_ipv4_2="\
No update. 変更はありません\n\
"
### E-mail message body if XML file is updated (there is difference between ###
### newly uploaded file and last-uploaded file)                             ###
mail_ipv4_3="\
O365 class-list file for IPv4 is uploaded. \n\
IPv4アドレスの変更がありclass-listをアップロードしました\n\
Uploaded file: ${archive_cl_all_ipv4}.txt\n\
diff result: ${diff_result_all_ipv4} \n\
"
### E-mail message body if a created class-list is empty ###
mail_ipv4_4="\
Uploading class-list is canseled since a created class-list for IPv4 is empty.\n\
Please check the XML page and the class-list\n\
生成されたIPv4のclass-listが空であるためアップロードを中止しました。XMLファイルを確認してください\n\
Updated file: ${archive_cl_all_ipv4}.txt\n\
URL: $url_xml \n\
"
### E-mail message body if IPv6 class-list ####################################
mail_ipv6_message="\n\
+++ class-list for IPv6 +++\n"
### E-mail message body if IPv6 addresses is not updated ###
mail_ipv6_2="\
No update. 変更はありません\n\
"
### E-mail message body if XML file is updated (there is difference between ###
### newly uploaded file and last-uploaded file)                             ###
mail_ipv6_3="\
O365 class-list file for IPv6 is uploaded. \n\
IPv6アドレスの変更がありclass-listをアップロードしました\n\
Uploaded file: ${archive_cl_all_ipv6}.txt\n\
diff result: ${diff_result_all_ipv6} \n\
"
### E-mail message body if a created class-list is empty ###
mail_ipv6_4="\
Uploading class-list is canseled since a created class-list for IPv6 is empty.\n\
Please check the XML page and the class-list\n\
生成されたIPv6のclass-listが空であるためアップロードを中止しました。XMLファイルを確認してください\n\
Updated file: ${archive_cl_all_ipv6}.txt\n\
URL: $url_xml \n\
"

### E-mail message body for XML Last modified #############################
mail_xml_last_modified_message="\n\
+++ XML file last modified +++"
mail_html_last_modified_message="\n\
+++ HTML file last modified +++"
### No update
mail_last2="No update. 変更はありません\n\
"
### Updated
mail_last3="Updated!!! 更新されました!!!\n\
"
                                                                               #
### E-mail setting #############################################################

### Directories ################################################################
                                                                               #
### For archives for class-list, xml and html
archive_dir="archive"
### For aXAPI json config files
conf_dir="conf"
### For diff files
diff_dir="diff"
### For html GET error logs
err_dir="err"
                                                                               #
                                                                               #
                                                                               #
########  Variables CONFIGURATION  #############################################

########  Directory check  #####################################################
                                                                               #
cd `dirname $0` || exit 1
### if no file/directory exit, make them
if [[ ! -e ${archive_dir} ]]; then
  mkdir ${archive_dir}
fi
if [[ ! -e ${conf_dir} ]]; then
  mkdir ${conf_dir}
fi
if [[ ! -e ${diff_dir} ]]; then
  mkdir ${diff_dir}
fi
if [[ ! -e ${err_dir} ]]; then 
  mkdir ${err_dir} 
fi
                                                                               #
########  Directory check  #####################################################

########  Get xml and Create class-list for ALL URLs ###########################
                                                                               #
                                                                               #
                                                                               #
result_code=0
######## Verify o365 xml that HTTP response code is "200 OK" or not
if [[ `wget -nv --spider --timeout 60 -t 5 $url_xml 2>&1 | grep '200 OK' -c` = "0" ]]; then
  ######## if failed, save the result of HTTP GET
  curl -k -v --trace-ascii ./${err_dir}/${err_curl_xml_log} $url_xml
  result_code=1
else
  ######## if 200OK, Get o365 xml file
  wget $url_xml
  ### Get Last-Modified from http response header
  last_modified_xml=`wget -S --spider --timeout 60 -t 5 $url_xml 2>&1 | grep Last-Modified | sed -E 's/(\s)//g'`
  ######## create last_modified_xml.txt if not exit
  if [[ ! -e last_modified_xml.txt ]]; then
    touch last_modified_xml.txt
  fi
  ######## diff last-modified date between last-downloaded file and just-downloaded file
  if [[ `cat last_modified_xml.txt` = "$last_modified_xml" ]]; then
    ######## result: same date. 
    result_code_xml=2
  else
    ######## result: different date. Probaly xml updated.
    result_code_xml=3
    echo $last_modified_xml > last_modified_xml.txt
  fi
  ### Rename xml file
  xml_file=`echo $url_xml | sed -E 's/^.*\/(.*)$/\1/g'`
  ######## archive downloaded original xml file with timestamp
  mv -f $xml_file ./${archive_dir}/${archive_cl_all}.xml
  ######## create class-list
  echo 'cat products/product/addresslist[@type="URL"]/address' | \
    xmllint --shell ./${archive_dir}/${archive_cl_all}.xml | grep "<address>" | \
    sed -E 's/^.*(<address>(.*)<\/address>)$/\2/g' | \
    sed -E 's/^(.*\*\.|)(.*)$/\2/g' | \
    sed -E "s/^http.*:\/\///" | \
    grep '\.\*$' | \
    sed -E 's/^(.*)(\.\*)$/\1/g' | \
    sed -E "s/^/contains /g" | \
    sed 's/\(\/\).*/\1/' | \
    sed 's/\///g' | \
#    sed -E 's/^.*(<address>(.*)<\/address>)$/\2/g' | \
#    sed -E 's/^(.*\*\.|)(.*)$/\2/g' | \
#    grep '\.\*$' | \
#    sed -E 's/^(.*)(\.\*)$/\1/g' | \
#    sed -E 's/^/contains /g' | \
    tr A-Z a-z |sort |uniq >> ./${archive_dir}/${archive_cl_all}.txt
  echo 'cat products/product/addresslist[@type="URL"]/address' | \
    xmllint --shell ./${archive_dir}/${archive_cl_all}.xml | grep "<address>" | \
    sed -E 's/^.*(<address>(.*)<\/address>)$/\2/g' | \
    sed -E "s/^http.*:\/\///" | \
    grep -v '\.\*$' | \
    sed -E 's/^(.*\*\.|)(.*)$/\2/g' | \
    sed -E 's/(\*)//g' | \
    sed -E 's/(\s)//g' | \
    sed -E "s/^/ends-with /g" | \
    sed 's/\(\/\).*/\1/' | \
    sed 's/\///g' | \
#    sed -E 's/^.*(<address>(.*)<\/address>)$/\2/g' | \
#    grep -v '\.\*$' | \
#    sed -E 's/^(.*\*\.|)(.*)$/\2/g' | \
#    sed -E 's/(\*)//g' | \
#    sed -E 's/(\s)//g' | \
#    sed -E 's/^/ends-with /g' | \
    tr A-Z a-z |sort |uniq >> ./${archive_dir}/${archive_cl_all}.txt
  sed -i -E "1i class-list $class_list_name_all ac file" ./${archive_dir}/${archive_cl_all}.txt
  ######## Check if class-list is empty or not
  if [[ `cat  ./${archive_dir}/${archive_cl_all}.txt 2>&1 | grep -e 'ends-with' -e 'contains' -e 'equals' -e 'starts-with' -c` = "0" ]]; then
    result_code=4
  else
    ######## copy a last-uploaded file for diff
    if [[ -e ${class_list_name_all} ]]; then
      cp -f $class_list_name_all ${class_list_name_all}_last-uploaded
    else
      # if no file exits, make an empty file
      touch ${class_list_name_all}_last-uploaded
    fi
    ######## copy and rename a new archive classlist to upload
    cp -f ./${archive_dir}/${archive_cl_all}.txt $class_list_name_all
    ######## check difference between downloaded file and last uploaded file
    if diff -q ${class_list_name_all}_last-uploaded $class_list_name_all > /dev/null ; then
      ######## result: same file. no upload done
      result_code=2
    else
      ######## Save the result of diff command
      echo "diff ${class_list_name_all}_last-uploaded $class_list_name_all" >> ./${diff_dir}/${diff_result_all}
      diff ${class_list_name_all}_last-uploaded $class_list_name_all >> ./${diff_dir}/${diff_result_all}
      result_code=3
    fi
  fi
fi

                                                                               #
                                                                               #
                                                                               #
########  Get xml and Create class-list for ALL  ###############################

########  Create CRLs URL removed class-list from ALL URL  #####################
                                                                               #
                                                                               #
######## Check if XML file is successfully got
if [[ $result_code -ne 1 ]]; then
  ######## create class-list CRL
  echo 'cat products/product[@name="CRLs"]/addresslist[@type="URL"]/address' | \
    xmllint --shell ./${archive_dir}/${archive_cl_all}.xml | grep "<address>" | \
    sed -E 's/^.*(<address>(.*)<\/address>)$/\2/g' | \
    sed -E 's/^(.*\*\.|)(.*)$/\2/g' | \
    sed -E "s/^http.*:\/\///" | \
    grep '\.\*$' | \
    sed -E 's/^(.*)(\.\*)$/\1/g' | \
    sed -E "s/^/contains /g" | \
    sed 's/\(\/\).*/\1/' | \
    sed 's/\///g' | \
#    sed -E 's/^.*(<address>(.*)<\/address>)$/\2/g' | \
#    sed -E 's/^(.*\*\.|)(.*)$/\2/g' | \
#    grep '\.\*$' | \
#    sed -E 's/^(.*)(\.\*)$/\1/g' | \
#    sed -E 's/^/contains /g' | \
    tr A-Z a-z |sort |uniq >> ./${archive_dir}/${archive_cl_crl}.txt
  echo 'cat products/product[@name="CRLs"]/addresslist[@type="URL"]/address' | \
    xmllint --shell ./${archive_dir}/${archive_cl_all}.xml | grep "<address>" | \
    sed -E 's/^.*(<address>(.*)<\/address>)$/\2/g' | \
    sed -E "s/^http.*:\/\///" | \
    grep -v '\.\*$' | \
    sed -E 's/^(.*\*\.|)(.*)$/\2/g' | \
    sed -E 's/(\*)//g' | \
    sed -E 's/(\s)//g' | \
    sed -E "s/^/ends-with /g" | \
    sed 's/\(\/\).*/\1/' | \
    sed 's/\///g' | \
#    sed -E 's/^.*(<address>(.*)<\/address>)$/\2/g' | \
#    grep -v '\.\*$' | \
#    sed -E 's/^(.*\*\.|)(.*)$/\2/g' | \
#    sed -E 's/(\*)//g' | \
#    sed -E 's/(\s)//g' | \
#    sed -E 's/^/ends-with /g' | \
    tr A-Z a-z |sort |uniq >> ./${archive_dir}/${archive_cl_crl}.txt
    sed -i -E "1i class-list $class_list_name_crl ac file" ./${archive_dir}/${archive_cl_crl}.txt
    ######## copy a last-uploaded file for diff
    if [[ -e ${class_list_name_crl} ]]; then
      cp -f $class_list_name_crl ${class_list_name_crl}_last-uploaded
    else
      # if no file exits, make an empty file
      touch ${class_list_name_crl}_last-uploaded
    fi
    ######## copy and rename a new archive classlist to upload
    cp -f ./${archive_dir}/${archive_cl_crl}.txt $class_list_name_crl
    ######## check difference between downloaded file and last uploaded file
    if diff -q ${class_list_name_crl}_last-uploaded $class_list_name_crl > /dev/null ; then
      ######## result: same file. no upload done
      result_code_crl=1
    else
      ######## Save the result of diff command
      echo "diff ${class_list_name_crl}_last-uploaded $class_list_name_crl" >> ./${diff_dir}/${diff_result_crl}
      diff ${class_list_name_crl}_last-uploaded $class_list_name_crl >> ./${diff_dir}/${diff_result_crl}
      result_code_crl=2
    fi
    ######## create file
    cat $class_list_name_all $class_list_name_crl > pre_all_url_nocrl.txt
    sort pre_all_url_nocrl.txt | uniq -u > ./${archive_dir}/${archive_cl_nocrl}.txt
    ######## copy a last-uploaded file for diff
    if [[ -e ${class_list_name_nocrl} ]]; then
      cp -f $class_list_name_nocrl ${class_list_name_nocrl}_last-uploaded
    else
      # if no file exits, make an empty file
      touch ${class_list_name_nocrl}_last-uploaded
    fi
    ######## copy and rename a new archive classlist to upload
    cp -f ./${archive_dir}/${archive_cl_nocrl}.txt $class_list_name_nocrl
    ######## check difference between downloaded file and last uploaded file
    if diff -q ${class_list_name_nocrl}_last-uploaded $class_list_name_nocrl > /dev/null ; then
      result_code_clurl=1
      ######## result: same file. no upload done
    else
      ######## Save the result of diff command
      echo "diff ${class_list_name_nocrl}_last-uploaded $class_list_name_nocrl" >> ./${diff_dir}/${diff_result_nocrl}
      diff ${class_list_name_nocrl}_last-uploaded $class_list_name_nocrl >> ./${diff_dir}/${diff_result_nocrl}
      result_code_nocrl=2
    fi
fi
                                                                               #
                                                                               #
                                                                               #
########  Create CRLs URL removed class-list from ALL URL  #####################

########  Invalid characters check for URL  ####################################
                                                                               #

######## noCRL file check
grep '*\|,\|_\|\\\|/\|?\|~\|\^\|=\|]\|\[\|)\|(\|>\|<\|;\|:\|}\|{\|@\|!\|"\|#\|\$\|%\|&\|+' $class_list_name_nocrl > nocrl_invalid.txt
######## characters validation
if [[ `grep -c '' nocrl_invalid.txt` -eq 0 ]]; then
 echo valid
  result_code_validchk=0
 else
  result_code_validchk=1
 echo invalid
fi
                                                                              #
########  Invalid characters check for URL  ###################################


########  Get xml and Create class-list for IPv4  ##############################
                                                                               #
                                                                               #
                                                                               #
######## Check if ipv4 is enabled
if [[ "$get_ipv4" = "yes" ]]; then
######## Check if XML file is successfully got
if [[ $result_code -ne 1 ]]; then
  ######## create class-list
  result_code_ipv4=0
  tmpfile1=$(mktemp)
  echo 'cat products/product/addresslist[@type="IPv4"]/address' | \
    xmllint --shell ./${archive_dir}/${archive_cl_all}.xml  | grep "<address>" | \
    sed -E 's/^.*(<address>(.*)<\/address>)$/\2/g' | grep "/"  >> ${tmpfile1}
  echo 'cat products/product/addresslist[@type="IPv4"]/address' | \
    xmllint --shell ./${archive_dir}/${archive_cl_all}.xml | grep "<address>" | \
    sed -E 's/^.*(<address>(.*)<\/address>)$/\2/g' | grep -v "/" | \
    sed -E 's/$/\/32/g' >> ${tmpfile1}
  cat $tmpfile1 |sort |uniq >> ./${archive_dir}/${archive_cl_all_ipv4}.txt
  sed -i -E "1i class-list $class_list_name_all_ipv4 ipv4 file" ./${archive_dir}/${archive_cl_all_ipv4}.txt
  rm -f $tmpfile1
  ######## Check if class-list is empty or not
  if [[ `cat  ./${archive_dir}/${archive_cl_all_ipv4}.txt 2>&1 | wc -l` -lt 2 ]]; then
    result_code_ipv4=4
  else
    ######## copy a last-uploaded file for diff
    if [[ -e ${class_list_name_all_ipv4} ]]; then
      cp -f $class_list_name_all_ipv4 ${class_list_name_all_ipv4}_last-uploaded
    else
      # if no file exits, make an empty file
      touch ${class_list_name_all_ipv4}_last-uploaded
    fi
    ######## copy and rename a new archive classlist to upload
    cp -f ./${archive_dir}/${archive_cl_all_ipv4}.txt $class_list_name_all_ipv4
    ######## check difference between downloaded file and last uploaded file
    if diff -q ${class_list_name_all_ipv4}_last-uploaded $class_list_name_all_ipv4 > /dev/null ; then
      ######## result: same file. no upload done
      result_code_ipv4=2
    else
#      ######## aXAPI: Log in Thunder
#      result=`curl -H "Accept-Encoding: identity" \
#        -H "Content-Length: 57" -H "Content-type: application/json" \
#        -d "{\"credentials\": {\"username\": \"admin\", \"password\": \"a10\"}}" \
#        -k -s -X POST https://${thunder_ip}/axapi/v3/auth`
#      auth_token=`echo $result | sed -E 's/^.*\"signature\":\"([0-9a-z]*)\".*$/\1/g'`
#      ######## aXAPI: Import class-list
#      echo "{\"class-list\":{\"action\":\"import\",\"file\":\"${class_list_name_all_ipv4}\",\"file-handle\":\"${class_list_name_all_ipv4}\"}}" > ./${conf_dir}/o365_all_ipv4.json
#      curl -X POST -H "Accept-Encoding: identity" -H "Authorization: A10 ${auth_token}" \
#       -F json=@./${conf_dir}/o365_all_ipv4.json -F file=@${class_list_name_all_ipv4} \
#       -k -vv https://${thunder_ip}/axapi/v3/file/class-list
#      ######## aXAPI: Log Off
#      curl -H "Accept-Encoding: identity" \
#       -H "Content-type: application/json" \
#       -H "Authorization: A10 ${auth_token}" \
#       -k -s \
#       https://${thunder_ip}/axapi/v3/logoff > /dev/null
      ######## Save the result of diff command
      echo "diff ${class_list_name_all_ipv4}_last-uploaded $class_list_name_all_ipv4" >> ./${diff_dir}/${diff_result_all_ipv4}
      diff ${class_list_name_all_ipv4}_last-uploaded $class_list_name_all_ipv4 >> ./${diff_dir}/${diff_result_all_ipv4}
      result_code_ipv4=3
    fi
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
  result_code_ipv6=0
  tmpfile1=$(mktemp)
  ######## create class-list
  echo 'cat products/product/addresslist[@type="IPv6"]/address' | \
    xmllint --shell ./${archive_dir}/${archive_cl_all}.xml  | grep "<address>" | \
    sed -E 's/^.*(<address>(.*)<\/address>)$/\2/g' | grep "/"  >> ${tmpfile1}
  echo 'cat products/product/addresslist[@type="IPv6"]/address' | \
    xmllint --shell ./${archive_dir}/${archive_cl_all}.xml | grep "<address>" | \
    sed -E 's/^.*(<address>(.*)<\/address>)$/\2/g' | grep -v "/" | \
    sed -E 's/$/\/128/g' >> ${tmpfile1}
  cat $tmpfile1 |sort |uniq >> ./${archive_dir}/${archive_cl_all_ipv6}.txt
  sed -i -E "1i class-list $class_list_name_all_ipv6 ipv6 file" ./${archive_dir}/${archive_cl_all_ipv6}.txt
  rm -f $tmpfile1
  ######## Check if class-list is empty or not
  if [[ `cat  ./${archive_dir}/${archive_cl_all_ipv6}.txt 2>&1 | wc -l` -lt 2 ]]; then
    result_code_ipv6=4
  else
    ######## copy a last-uploaded file for diff
    if [[ -e ${class_list_name_all_ipv6} ]]; then
      cp -f $class_list_name_all_ipv6 ${class_list_name_all_ipv6}_last-uploaded
    else
      # if no file exits, make an empty file
      touch ${class_list_name_all_ipv6}_last-uploaded
    fi
    ######## copy and rename a new archive classlist to upload
    cp -f ./${archive_dir}/${archive_cl_all_ipv6}.txt $class_list_name_all_ipv6
    ######## check difference between downloaded file and last uploaded file
    if diff -q ${class_list_name_all_ipv6}_last-uploaded $class_list_name_all_ipv6 > /dev/null ; then
      ######## result: same file. no upload done
      result_code_ipv6=2
    else
#      ######## aXAPI: Log in Thunder
#      result=`curl -H "Accept-Encoding: identity" \
#        -H "Content-Length: 57" -H "Content-type: application/json" \
#        -d "{\"credentials\": {\"username\": \"admin\", \"password\": \"a10\"}}" \
#        -k -s -X POST https://${thunder_ip}/axapi/v3/auth`
#      auth_token=`echo $result | sed -E 's/^.*\"signature\":\"([0-9a-z]*)\".*$/\1/g'`
#      ######## aXAPI: Import class-list
#      echo "{\"class-list\":{\"action\":\"import\",\"file\":\"${class_list_name_all_ipv6}\",\"file-handle\":\"${class_list_name_all_ipv6}\"}}" > ./${conf_dir}/o365_all_ipv6.json
#      curl -X POST -H "Accept-Encoding: identity" -H "Authorization: A10 ${auth_token}" \
#       -F json=@./${conf_dir}/o365_all_ipv6.json -F file=@${class_list_name_all_ipv6} \
#       -k -vv https://${thunder_ip}/axapi/v3/file/class-list
#      ######## aXAPI: Log Off
#      curl -H "Accept-Encoding: identity" \
#       -H "Content-type: application/json" \
#       -H "Authorization: A10 ${auth_token}" \
#       -k -s \
#       https://${thunder_ip}/axapi/v3/logoff > /dev/null
      ######## Save the result of diff command
      echo "diff ${class_list_name_all_ipv6}_last-uploaded $class_list_name_all_ipv6" >> ./${diff_dir}/${diff_result_all_ipv6}
      diff ${class_list_name_all_ipv6}_last-uploaded $class_list_name_all_ipv6 >> ./${diff_dir}/${diff_result_all_ipv6}
      result_code_ipv6=3
    fi
  fi
fi
fi
                                                                               #
                                                                               #
                                                                               #
########  Get xml and Create class-list for IPv6  ##############################


########  Send e-mail ##########################################################
                                                                               #
                                                                               #
                                                                               #

######## Create mail title and message for all URLs ############################
                                                                               #
                                                                               #
# variable for line break code for base64
CR=$(printf '\r')  
# temp file for attachments
tmp_base64=$(mktemp)
tmp_attachment=$(mktemp)
# if failed to get XML file ####################################################
if [[ $result_code -eq 1 ]]; then
  mail_subject="O365 class-list | all URLs/IPv4/IPv6 failure | "
  mail_message="$mail_message$mail_all_url_message$mail_1"
  # create an attachment of curl debug file in base64 format
  cat ./${err_dir}/${err_curl_xml_log} | sed "/^\$/s/\$/$CR/" | sed "/[^$CR]\$/s/\$/$CR/" | base64 > $tmp_base64
  # create SMTP headers
  echo "--$_DATE_TIME"   > $tmp_attachment
  echo 'MIME-Version: 1.0'   >>  $tmp_attachment
  echo "Content-Type: application/octet-stream; name="${err_curl_xml_log}"" >> $tmp_attachment
  echo 'Content-Transfer-Encoding: base64'  >>  $tmp_attachment
  echo "Content-Disposition: attachment; filename="${err_curl_xml_log}"" >>  $tmp_attachment
  echo '' >> $tmp_attachment
  cat $tmp_base64 >> $tmp_attachment
  echo '' >> $tmp_attachment
# if class-list for all URLs file is not updated ###############################
elif [[ $result_code -eq 2 ]]; then
  mail_subject="O365 class-list | all URLs NO update | "
  mail_message="$mail_message$mail_all_url_message$mail_2"
# if class-list for all URLs file is updated (there is difference between ######
# newly uploaded file and last-uploaded file) ##################################
elif [[ $result_code -eq 3 ]]; then
  mail_subject="O365 class-list | all URLs UPDATED | "
  mail_message="$mail_message$mail_all_url_message$mail_3"
  # create attachment of diff file in base64 format
  cat ./${diff_dir}/${diff_result_all} | sed "/^\$/s/\$/$CR/" | sed "/[^$CR]\$/s/\$/$CR/" | base64 > $tmp_base64
  # create SMTP headers
  echo "--$_DATE_TIME"   >> $tmp_attachment
  echo 'MIME-Version: 1.0'   >>  $tmp_attachment
  echo "Content-Type: application/octet-stream; name="${diff_result_all}"" >> $tmp_attachment
  echo 'Content-Transfer-Encoding: base64'  >>  $tmp_attachment
  echo "Content-Disposition: attachment; filename="${diff_result_all}"" >>  $tmp_attachment
  echo '' >> $tmp_attachment
  cat $tmp_base64 >> $tmp_attachment
  echo '' >> $tmp_attachment
  # create attachment of class-list file in base64 format
  cat ${class_list_name_all} | sed "/^\$/s/\$/$CR/" | sed "/[^$CR]\$/s/\$/$CR/" | base64 > $tmp_base64
  # create SMTP headers
  echo "--$_DATE_TIME"   >> $tmp_attachment
  echo 'MIME-Version: 1.0'   >>  $tmp_attachment
  echo "Content-Type: application/octet-stream; name="${class_list_name_all}.txt"" >> $tmp_attachment
  echo 'Content-Transfer-Encoding: base64'  >>  $tmp_attachment
  echo "Content-Disposition: attachment; filename="${class_list_name_all}.txt"" >>  $tmp_attachment
  echo '' >> $tmp_attachment
  cat $tmp_base64 >> $tmp_attachment
  echo '' >> $tmp_attachment
  # create attachment of diff file in base64 format noCRL
  cat ./${diff_dir}/${diff_result_nocrl} | sed "/^\$/s/\$/$CR/" | sed "/[^$CR]\$/s/\$/$CR/" | base64 > $tmp_base64
  # create SMTP headers
  echo "--$_DATE_TIME"   >> $tmp_attachment
  echo 'MIME-Version: 1.0'   >>  $tmp_attachment
  echo "Content-Type: application/octet-stream; name="${diff_result_nocrl}"" >> $tmp_attachment
  echo 'Content-Transfer-Encoding: base64'  >>  $tmp_attachment
  echo "Content-Disposition: attachment; filename="${diff_result_nocrl}"" >>  $tmp_attachment
  echo '' >> $tmp_attachment
  cat $tmp_base64 >> $tmp_attachment
  echo '' >> $tmp_attachment
  # create attachment of class-list file in base64 format noCRL
  cat ${class_list_name_nocrl} | sed "/^\$/s/\$/$CR/" | sed "/[^$CR]\$/s/\$/$CR/" | base64 > $tmp_base64
  # create SMTP headers
  echo "--$_DATE_TIME"   >> $tmp_attachment
  echo 'MIME-Version: 1.0'   >>  $tmp_attachment
  echo "Content-Type: application/octet-stream; name="${class_list_name_nocrl}.txt"" >> $tmp_attachment
  echo 'Content-Transfer-Encoding: base64'  >>  $tmp_attachment
  echo "Content-Disposition: attachment; filename="${class_list_name_nocrl}.txt"" >>  $tmp_attachment
  echo '' >> $tmp_attachment
  cat $tmp_base64 >> $tmp_attachment
  echo '' >> $tmp_attachment
# if creating class-list for all URLs is failed ################################
elif [[ $result_code -eq 4 ]]; then
  mail_subject="O365 class-list | all URLs upload Canceled | "
  mail_message="$mail_message$mail_all_url_message$mail_4"
  # create attachment of class-list file in base64 format
  cat ./${archive_dir}/${archive_cl_all}.txt | sed "/^\$/s/\$/$CR/" | sed "/[^$CR]\$/s/\$/$CR/" | base64 > $tmp_base64
  # create SMTP headers
  echo "--$_DATE_TIME"   >> $tmp_attachment
  echo 'MIME-Version: 1.0'   >>  $tmp_attachment
  echo "Content-Type: application/octet-stream; name="${archive_cl_all}.txt"" >> $tmp_attachment
  echo 'Content-Transfer-Encoding: base64'  >>  $tmp_attachment
  echo "Content-Disposition: attachment; filename="${archive_cl_all}.txt"" >>  $tmp_attachment
  echo '' >> $tmp_attachment
  cat $tmp_base64 >> $tmp_attachment
  echo '' >> $tmp_attachment
else #result_code=0
  echo "ERROR!"
  exit 1
fi

######## Create mail title and message for validation ##########################
                                                                               #
                                                                               #

# if URL includ invalid characters  ################################
if [[ $result_code_validchk -eq 1 ]]; then
  mail_subject="O365 class-list | URLs include invalid characters | "
  mail_message="$mail_message$mail_character_validation_message$mail_5"
  # create attachment of class-list file in base64 format
  cat nocrl_invalid.txt | base64 > $tmp_base64
  # create SMTP headers
  echo "--$_DATE_TIME"   >> $tmp_attachment
  echo 'MIME-Version: 1.0'   >>  $tmp_attachment
  echo "Content-Type: application/octet-stream; name="nocrl_invalid.txt"" >> $tmp_attachment
  echo 'Content-Transfer-Encoding: base64'  >>  $tmp_attachment
  echo "Content-Disposition: attachment; filename="nocrl_invalid.txt"" >>  $tmp_attachment
  echo '' >> $tmp_attachment
#  cat nocrl_invalid.txt >> $tmp_attachment 
  cat $tmp_base64 >> $tmp_attachment
  echo '' >> $tmp_attachment
# if URL does not have invalid characters  ###############################
elif [[ $result_code_validchk -eq 0 ]]; then
  mail_subject="O365 class-list | No invalid characters | "
  mail_message="$mail_message$mail_character_validation_message$mail_6"
else #result_code=0
  echo "ERROR!"
  exit 1
fi


######## Create mail title and message for IPv4 ################################
                                                                               #
                                                                               #
if [[ "$get_ipv4"="yes" ]]; then
  # if no update 
  if [[ $result_code_ipv4  -eq 2 ]]; then
    mail_subject=$mail_subject"IPv4 NO update | "
    mail_message="$mail_message$mail_ipv4_message$mail_ipv4_2"
  # if HTML file is updated (there is difference between newly uploaded file and last-uploaded file)
  elif [[ $result_code_ipv4  -eq 3 ]]; then
    mail_subject=$mail_subject"IPv4 UPDATED | "
    mail_message="$mail_message$mail_ipv4_message$mail_ipv4_3"
    # create attachment of diff file in base64 format
    cat ./${diff_dir}/${diff_result_all_ipv4} | sed "/^\$/s/\$/$CR/" | sed "/[^$CR]\$/s/\$/$CR/" | base64 > $tmp_base64
    # create SMTP headers
    echo "--$_DATE_TIME"   >> $tmp_attachment
    echo 'MIME-Version: 1.0'   >>  $tmp_attachment
    echo "Content-Type: application/octet-stream; name="${diff_result_all_ipv4}"" >> $tmp_attachment
    echo 'Content-Transfer-Encoding: base64'  >>  $tmp_attachment
    echo "Content-Disposition: attachment; filename="${diff_result_all_ipv4}"" >>  $tmp_attachment
    echo '' >> $tmp_attachment
    cat $tmp_base64 >> $tmp_attachment
    echo '' >> $tmp_attachment
    # create attachment of class-list file in base64 format
    cat ${class_list_name_all_ipv4} | sed "/^\$/s/\$/$CR/" | sed "/[^$CR]\$/s/\$/$CR/" | base64 > $tmp_base64
    # create SMTP headers
    echo "--$_DATE_TIME"   >> $tmp_attachment
    echo 'MIME-Version: 1.0'   >>  $tmp_attachment
    echo "Content-Type: application/octet-stream; name="${class_list_name_all_ipv4}.txt"" >> $tmp_attachment
    echo 'Content-Transfer-Encoding: base64'  >>  $tmp_attachment
    echo "Content-Disposition: attachment; filename="${class_list_name_all_ipv4}.txt"" >>  $tmp_attachment
    echo '' >> $tmp_attachment
    cat $tmp_base64 >> $tmp_attachment
    echo '' >> $tmp_attachment
  elif [[ $result_code_ipv4  -eq 4 ]]; then
    mail_subject=$mail_subject"IPv4 upload Canceled | "
    mail_message="$mail_message$mail_ipv4_message$mail_ipv4_4"
    # create attachment of class-list file in base64 format
    cat ./${archive_dir}/${archive_cl_all_ipv4}.txt | sed "/^\$/s/\$/$CR/" | sed "/[^$CR]\$/s/\$/$CR/" | base64 > $tmp_base64
    # create SMTP headers
    echo "--$_DATE_TIME"   >> $tmp_attachment
    echo 'MIME-Version: 1.0'   >>  $tmp_attachment
    echo "Content-Type: application/octet-stream; name="${archive_cl_all_ipv4}.txt"" >> $tmp_attachment
    echo 'Content-Transfer-Encoding: base64'  >>  $tmp_attachment
    echo "Content-Disposition: attachment; filename="${archive_cl_all_ipv4}.txt"" >>  $tmp_attachment
    echo '' >> $tmp_attachment
    cat $tmp_base64 >> $tmp_attachment
    echo '' >> $tmp_attachment
  else #result_code=0
    echo "ERROR!"
  fi
fi

######## Create mail title and message for IPv6 ################################
                                                                               #
                                                                               #
if [[ "$get_ipv6"="yes" ]]; then
  # if no update 
  if [[ $result_code_ipv6  -eq 2 ]]; then
    mail_subject=$mail_subject"IPv6 NO update | "
    mail_message="$mail_message$mail_ipv6_message$mail_ipv6_2"
  # if HTML file is updated (there is difference between newly uploaded file and last-uploaded file)
  elif [[ $result_code_ipv6  -eq 3 ]]; then
    mail_subject=$mail_subject"IPv6 UPDATED | "
    mail_message="$mail_message$mail_ipv6_message$mail_ipv6_3"
    # create attachment of diff file in base64 format
    cat ./${diff_dir}/${diff_result_all_ipv6} | sed "/^\$/s/\$/$CR/" | sed "/[^$CR]\$/s/\$/$CR/" | base64 > $tmp_base64
    # create SMTP headers
    echo "--$_DATE_TIME"   >> $tmp_attachment
    echo 'MIME-Version: 1.0'   >>  $tmp_attachment
    echo "Content-Type: application/octet-stream; name="${diff_result_all_ipv6}"" >> $tmp_attachment
    echo 'Content-Transfer-Encoding: base64'  >>  $tmp_attachment
    echo "Content-Disposition: attachment; filename="${diff_result_all_ipv6}"" >>  $tmp_attachment
    echo '' >> $tmp_attachment
    cat $tmp_base64 >> $tmp_attachment
    echo '' >> $tmp_attachment
    # create attachment of class-list file in base64 format
    cat ${class_list_name_all_ipv6} | sed "/^\$/s/\$/$CR/" | sed "/[^$CR]\$/s/\$/$CR/" | base64 > $tmp_base64
    # create SMTP headers
    echo "--$_DATE_TIME"   >> $tmp_attachment
    echo 'MIME-Version: 1.0'   >>  $tmp_attachment
    echo "Content-Type: application/octet-stream; name="${class_list_name_all_ipv6}.txt"" >> $tmp_attachment
    echo 'Content-Transfer-Encoding: base64'  >>  $tmp_attachment
    echo "Content-Disposition: attachment; filename="${class_list_name_all_ipv6}.txt"" >>  $tmp_attachment
    echo '' >> $tmp_attachment
    cat $tmp_base64 >> $tmp_attachment
    echo '' >> $tmp_attachment
  elif [[ $result_code_ipv6  -eq 4 ]]; then
    mail_subject=$mail_subject"IPv6 upload Canceled | "
    mail_message="$mail_message$mail_ipv6_message$mail_ipv6_4"
    # create attachment of class-list file in base64 format
    cat ./${archive_dir}/${archive_cl_all_ipv6}.txt | sed "/^\$/s/\$/$CR/" | sed "/[^$CR]\$/s/\$/$CR/" | base64 > $tmp_base64
    # create SMTP headers
    echo "--$_DATE_TIME"   >> $tmp_attachment
    echo 'MIME-Version: 1.0'   >>  $tmp_attachment
    echo "Content-Type: application/octet-stream; name="${archive_cl_all_ipv6}.txt"" >> $tmp_attachment
    echo 'Content-Transfer-Encoding: base64'  >>  $tmp_attachment
    echo "Content-Disposition: attachment; filename="${archive_cl_all_ipv6}.txt"" >>  $tmp_attachment
    echo '' >> $tmp_attachment
    cat $tmp_base64 >> $tmp_attachment
    echo '' >> $tmp_attachment
  else #result_code=0
    echo "ERROR!"
  fi
fi


# Create a message for last modified date of XML  ##############################
                                                                               #
                                                                               #
### check last modified for XML
if [[ $result_code -ne 1 ]]; then
  # No update
  if [[ $result_code_xml -eq 2 ]]; then
    mail_message="$mail_message$mail_xml_last_modified_message\n$mail_last2$last_modified_xml"
  # Updated
  elif [[ $result_code_xml -eq 3 ]]; then
    mail_message="$mail_message$mail_xml_last_modified_message\n$mail_last3$last_modified_xml\n$url_xml"
  fi
fi

#### Add Thunder IP in the end of email subject
mail_subject=$mail_subject"Thunder: $thunder_ip"
#### Add boundary in the end of body
echo "--$_DATE_TIME--" >> $tmp_attachment
######## Send email ########

tmp_head_msg=$(mktemp)
# header
echo "From: '$mail_from_name' <$mail_from_ad>" > $tmp_head_msg
echo "To: $mail_to" >> $tmp_head_msg
echo "Subject: $mail_subject" >> $tmp_head_msg
echo 'MIME-Version: 1.0' >>  $tmp_head_msg
echo 'Content-Transfer-Encoding: 7bit' >> $tmp_head_msg
echo "Content-Type: multipart/mixed; boundary="$_DATE_TIME"" >> $tmp_head_msg
echo '' >> $tmp_head_msg

# BODY message
echo "--$_DATE_TIME"   >>  $tmp_head_msg
echo 'Content-Transfer-Encoding: base64' >> $tmp_head_msg
echo 'Content-Type: text/plain; charset="UTF-8"' >> $tmp_head_msg
echo '' >> $tmp_head_msg
tmp_msg1=$(mktemp)
tmp_msg2=$(mktemp)
echo $mail_message > $tmp_msg1
LF=$(printf '\\\012_')
LF=${LF%_}
cat $tmp_msg1 | sed 's/\\n/'"$LF"'/g' | base64 > $tmp_msg2
cat $tmp_msg2 >> $tmp_head_msg
echo ''  >> $tmp_head_msg

cat $tmp_attachment >> $tmp_head_msg
cat $tmp_head_msg | sendmail -t

cat $tmp_head_msg
cat $tmp_attachment

rm -f $tmp_base64
rm -f $tmp_attachment
rm -f $tmp_msg1
rm -f $tmp_msg2
                                                                               #
                                                                               #
                                                                               #
########  Send e-mail ##########################################################
exit 0

