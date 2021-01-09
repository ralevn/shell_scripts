#!/usr/bin/ksh

PHF="PATH HAS FAILED"
PHR="PATH HAS RECOVERED"
LE="LINK ERROR"
NOW=$(date +%m%d%H%M%y)
MAIL_FROM="root@$(hostname)"
MAIL_TO="nikolai.ralev@dxc.com,mahalingaiah.chikkeerappa@dxc.com"
MAIL_SUBJ="$(hostname) : New ${PHF} and ${PHR} Errors"
MSG_TMPFILE="./msgtmpfile.$(date +%d%m%Y).txt"
echo "" > ${MSG_TMPFILE}



## If check if /tmp/errpt.tmp1 exists if Not create and save
## number of path and link errors this will be kept for
## comparison next run of the script with /tmp/errpt.tmp2

if [ ! -w /tmp/errpt.tmp1 ]; then
   touch /tmp/errpt.tmp1
   errpt|awk -v phf="$PHF" -v phr="$PHR" -v lie="$LE" '
                $0 ~ phf {f[$1] ++}
                $0 ~ phr {r[$1] ++}
                $0 ~ lie {l[$1] ++}
                END {
                        for (i in f) print i,f[i],"\""phf"\""
                        for (j in r) print j,r[j],"\""phr"\""
                        for (k in l) print k,l[k],"\""lie"\""
                    }
         ' > /tmp/errpt.tmp1
fi

## If check if /tmp/errpt.tmp2 exists if Not create and save
## number of path and link errors. This will be compared with
## /tmp/errpt.tmp1 then it will be moved as /tmp/errpt.tmp1 and
## delted

if [ ! -w /tmp/errpt.tmp2 ]; then
   touch /tmp/errpt.tmp2
   errpt|awk -v phf="$PHF" -v phr="$PHR" -v lie="$LE" '
                $0 ~ phf {f[$1] ++}
                $0 ~ phr {r[$1] ++}
                $0 ~ lie {l[$1] ++}
                END {
                        for (i in f) print i,f[i],"\""phf"\""
                        for (j in r) print j,r[j],"\""phr"\""
                        for (k in l) print k,l[k],"\""lie"\""
                    }
         ' > /tmp/errpt.tmp2
fi

## Calculate No of erros 10 min before
typeset -i PHF1=$(awk -v phf="$PHF" '$0 ~ phf {i+=$2} END {print i}' /tmp/errpt.tmp1)
typeset -i PHR1=$(awk -v phr="$PHR" '$0 ~ phr {i+=$2} END {print i}' /tmp/errpt.tmp1)
typeset -i LE1=$(awk -v lie="$LE" '$0 ~ lie {i+=$2} END {print i}' /tmp/errpt.tmp1)

## Calculate No of errors now
typeset -i PHF2=$(awk -v phf="$PHF" '$0 ~ phf {i+=$2} END {print i}' /tmp/errpt.tmp2)
typeset -i PHR2=$(awk -v phr="$PHR" '$0 ~ phr {i+=$2} END {print i}' /tmp/errpt.tmp2)
typeset -i LE2=$(awk -v lie="$LE" '$0 ~ lie {i+=$2} END {print i}' /tmp/errpt.tmp2)

NEW_PHF=$(expr ${PHF2} - ${PHF1})
NEW_PHR=$(expr ${PHR2} - ${PHR1})
NEW_LE=$(expr ${LE2} - ${LE1})

crerate_msg ()
{
echo "There are new errors of type ${PHF} and ${PHF} on $(hostname).\nPlease take actions:" >> ${MSG_TMPFILE}
echo "----------------------------------------------- " >> ${MSG_TMPFILE}
echo "New errors of type: ${PHF} : ${NEW_PHF}" >> ${MSG_TMPFILE}
echo "New errors of type: ${PHR} : ${NEW_PHR}" >> ${MSG_TMPFILE}
echo "New errors of type: ${LE} : ${NEW_LE}\n" >> ${MSG_TMPFILE}
echo "Details as of $(date +%T) $(date +%d%m%Y)  :" >> ${MSG_TMPFILE}
echo "Error    Count   Type" >> ${MSG_TMPFILE}
echo "----------------------" >> ${MSG_TMPFILE}
cat /tmp/errpt.tmp1 >> ${MSG_TMPFILE}
}

mail_it ()
{
sendmail -t << _EOF
From: ${MAIL_FROM}
To: ${MAIL_TO}
Subject: ${MAIL_SUBJ}
$(cat ${MSG_TMPFILE})
_EOF
}

## Test if mail to be sent depends of Number of new messages
if [ $NEW_PHF -gt 0 -o $NEW_PHR -gt 0 -o NEW_LE -gt 0 ]
then
        crerate_msg
        mail_it
##else  echo "I sent nothing"
fi

rm -f  ${MSG_TMPFILE}
mv -f /tmp/errpt.tmp2 /tmp/errpt.tmp1
