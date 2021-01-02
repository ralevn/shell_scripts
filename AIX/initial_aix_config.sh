#!/usr/bin/ksh

message() {
        #$1 Group message
        #$2 Test
        #$3 Status
        #$4 Reason
        m_msg=$1
        m_tst=$2
        m_status=$3
        m_reason=$4
        printf "%.70s %s\n" "${m_msg}: ${m_tst} ............................................................" "Status: ${m_status} Reason: ${m_reason}"
}

ch_kernel_p()  { #$1 = parameter, $2 value, $3 run,reboot,both $4 cmd
        #$1 = parameter
        #$2 = value
        #$3 = mode
        #$4 = command
        ###checks are applied only to parameter and mode, value parameter is not checked due to complexity so you must know what you are doing with this function
        param=$1
        value=$2
        ch=$3
        cmd=$4
        ##sanity checks, if kernel paramer is real and run,reboot,both is supplied - kernel value is not checked so you must know what you are suppling and if the value is a valid one.
        if ! [[ $ch == "run" || $ch == "reboot" || $ch == "both" ]];then
                fn_msg="Mode incompatible"
                message "Kernel Param" "Parameter: $param" "Error" "$fn_msg"
                return 1
        fi
        get_param=$($cmd -a |grep -w $param |wc -l|xargs)
        if [[ $get_param != 1 ]];then
                fn_msg="Wrong parameter"
                message "Kernel Param" "Parameter: $param" "Error" "$fn_msg"
                return 1
        fi
        get_cmd=$(which $cmd|wc -l|xargs)
        if [[ $get_cmd != 1 ]];then
                fn_msg="Wrong command"
                message "Kernel Param" "Parameter: $param" "Error" "$fn_msg"
                return 1
        fi
        switches=""
        if [[ $ch == "run" ]];then
                switches=""
        elif [[ $ch == "reboot" ]];then
                switches="-r"
        elif [[ $ch == "both" ]];then
                switches="-p"
        fi
        ##Make the change as requested
        $cmd $switches -o $param=$value
        message "Kernel Param" "Parameter: $param set $value at $ch" "Done" "OK"
        return 0
}
rm_itab() { #$1 service name, function will check if entry is present and remove it if so
        srv=$1
        #find out if the service is available
        get_srv=$(lsitab $srv|wc -l|xargs);
        if [[ $get_srv != 1 ]];then
                fn_msg="Service not present"
                message "Services Remove" "Service: $srv" "Skip" "$fn_msg"
                return 1
        fi
        rmitab $srv
        message "Services Remove" "Service: $srv" "Done" "OK"
        return 0
}

stop_inetd() { # function takes as and argument the name of the subsystem controlled by inetd master system
        subsys=$1
        #Check if the required subsystem is not commented in the config file
        if [[ $(grep -c "^$subsys" /etc/inetd.conf) == 1 ]]; then
                echo "s/^$subsys/##&/" >> /tmp/inetd.sed
                cp -p /etc/inetd.conf /tmp/inetd.conf
                sed -f /tmp/inetd.sed /tmp/inetd.conf > /etc/inetd.conf
                rm -f /tmp/inetd.sed
                rm -f /tmp/inetd.conf
        fi
        #Check if subsystem is running and refresh the master daemon if necessary
        if [[ $(lssrc -l -s inetd|grep -c $subsys) == 1 ]];then
                refresh -s inetd
                printf "%.50s %s\n" "Stopping $subsys Daemon .............................." "Status: Done. Reason: OK"
        else
                printf "%.50s %s\n" "Stopping $subsys Daemon .............................." "Status: Skip. Reason: inoperative"
        fi
}
stop_src()  { #function takes as argument the subsystem name and stops it via the stopsrc utility
        subsys=$1
        if [[ $(lssrc -s $subsys|grep -c active) == 1 ]];then
                stopsrc -s $subsys
                printf "%.50s %s\n" "Stopping $subsys Daemon .............................." "Status: Done. Reason: OK"
        else
                printf "%.50s %s\n" "Stopping $subsys Daemon .............................." "Status: Skip. Reason: inoperative"
        fi

}

ch_login () { #function takes as argument the "stanza" and parameter=value
        #$1 = stanza
        #$2 = parameter=value
        stanza=$1
        param=$2
        attribute=$(echo $param|cut -d "=" -f1)
        #change the value if there is a mismatch of the parameter supplied for the supplied stanza
        if [[ $(lssec -f /etc/security/login.cfg -s $stanza -a $attribute|awk '{print $2}') != $param ]];then
                chsec -f /etc/security/login.cfg -s $stanza -a $param
                printf "%.50s %s\n" "Login config, $param .............................." "Status: Done. Reason: OK"
        else
                printf "%.50s %s\n" "Login config, $param .............................." "Status: Skip. Reason: Existing"
        fi
}

ch_pwd () { #function takes as argument the stanza and parameter=value
        #$1 = stanza
        #$2 = parameter=value
        stanza=$1
        param=$2
        attribute=$(echo $param|cut -d "=" -f1)
        #change the value if there is a mismatch of the parameter supplied for the supplied stanza
        if [[ $(lssec -f /etc/security/user -s $stanza -a $attribute|awk '{print $2}') != $param ]];then
                chsec -f /etc/security/user -s $stanza -a $param
                printf "%.50s %s\n" "Password config, $param .............................." "Status: Done. Reason: OK"
        else
                printf "%.50s %s\n" "Password config, $param .............................." "Status: Skip. Reason: Existing"
        fi
}
ch_sysparam () { #arguments      are $1=device handler example - sys0 and parameter=value
#$1 = hnd
#$2 = parameter=value
        hnd=$1
        param=$2
        attribute=$(echo $param|cut -d "=" -f1)
        value=$(echo $param|cut -d "=" -f2)
        #Check if the current value matches the provided one for the specified handler
        if [[ $(lsattr -El $hnd -a $attribute|awk '{print $2}') != $value ]];then
                chdev -l $hnd -a $param
                chdev -l $hnd -a $param -P
                printf "%.50s %s\n" "System Parameters, device: $hnd $param .............................." "Status: Done. Reason: OK, reboot might be required"
        else
                printf "%.50s %s\n" "System Parameters, device: $hnd $param .............................." "Status: Skip. Reason: Existing"
        fi
}

ch_rctcpip() { #argumensts are $1 subsystem $2 action (enable|disable) $3 apply (config|all)
#$1 = subsystem
#$2 = action values are: enable|disable
#$3 = apply values are: config(only apply to config file but do not start or stop, all (apply to config and do stop|start the daemon)
        subsys=$1
        action=$2
        apply=$3
        act=""
        appl=""
        case $action in
                enable)
                        act="-a"
                        command="Enable"
                ;;
                disable)
                        act="-d"
                        command="Disable"
                ;;
                *) echo "Invalid argument"; return 1;
                ;;
        esac
        case $apply in
                config)
                        appl=""
                        c_daemon="Config only"
                ;;
                all)
                        appl="-S"
                        if [[ $command == "Enable" ]];then
                                c_daemon="Start"
                        else
                                c_daemon="Stop"
                        fi
                ;;
                *) echo "Invalid argument"; return 1;
                ;;
        esac
        printf "%.50s %s\n" "$c_daemon $subsys daemon .............................." "Status: $command. Reason: OK"
        /usr/sbin/chrctcp $appl $act $subsys
}


###Fixing NTP configuration
##Time and Zone fix
if [[ $(lssrc -s xntpd|grep -c active) != 1 ]];then
        ##Equalize the system clock to the provided NTP server
        ntpdate 10.179.88.11
        printf "%.50s %s\n" "System clock sync with NTP .............................." "Status: Done. Reason: OK"
        ##Change the Timezone to 'Europe/Amsterdam'
        chtz 'Europe/Amsterdam'
        printf "%.50s %s\n" "Timezone Europe/Amsterdam .............................." "Status: Done. Reason: Reboot required"
else
        printf "%.50s %s\n" "System clock sync with NTP .............................." "Status: Skip. Reason: xntpd running"
fi

##NTP daemon start and config
if [[ $(grep -c "Deployed by provisioning script" /etc/ntp.conf) != 1 ]];then
        echo "#Deployed by provisioning script" >> /etc/ntp.conf
        echo "server 10.179.88.11 iburst" >> /etc/ntp.conf
        echo "server 10.179.88.10 iburst" >> /etc/ntp.conf
        printf "%.50s %s\n" "Fixing /etc/ntp.conf .............................." "Status: Done. Reason: OK"
        /usr/sbin/chrctcp -S -a xntpd
        if [[ $(lssrc -s xntpd|grep -v Subsystem|awk '{print $4}') == "active" ]];then
                printf "%.50s %s\n" "Start xntpd daemon .............................." "Status: active. Reason: OK"
        else
                printf "%.50s %s\n" "Start xntpd daemon .............................." "Status: inoperative. Reason: Fail"
        fi
else
        printf "%.50s %s\n" "NTP configured .............................." "Status: Skip. Reason: Existing"
fi

###Setting up DNS servers
if [[ $(grep -c "Deployed by provisioning script" /etc/resolv.conf) != 1 ]];then
cat > /etc/resolv.conf << EOF
#Deployed by provisioning script
search  UWV-MGMT.svcs.entsvcs.com
nameserver      10.179.88.10
nameserver      10.179.88.11
EOF
        printf "%.50s %s\n" "Fixing /etc/resolv.conf .............................." "Status: Done. Reason: OK"

else
        printf "%.50s %s\n" "Fixing /etc/resolv.conf .............................." "Status: Skip. Reason: Existing"
fi


###FIXING THE /etc/profile file
if [[ $(grep -c "Deployed by provisioning script" /etc/profile) != 1 ]];then
cat > /tmp/profile.sed << 'EOF'
s/trap 1 2 3/\
#Deployed by provisioning script\
HOSTNAME=`\/usr\/bin\/hostname`\
USER=`\/usr\/bin\/whoami`\
PS1=$PS1$(echo ""[$USER@$HOSTNAME:""'$PWD'""]#)\
export PS1\
set -o vi\
umask 027\
mesg n\
trap 1 2 3/g
EOF
        cp -p /etc/profile /tmp/profile.txt
        sed -f /tmp/profile.sed /tmp/profile.txt > /etc/profile
        rm -f /tmp/profile.sed
        rm -f /tmp/profile.txt
        printf "%.50s %s\n" "Fixing /etc/profile .............................." "Status: Done. Reason: OK"
else
        printf "%.50s %s\n" "Fixing /etc/profile .............................." "Status: Skip. Reason: Existing"
fi
###Fixing the CSH.login file to disable messaging on the terminal if not present
if [[ $(cat /etc/csh.login|grep -c "^mesg n") == 0 ]];then
        echo "mesg n" >> /etc/csh.login
        printf "%.50s %s\n" "Fixing /etc/csh.login .............................." "Status: Done. Reason: OK"
else
        printf "%.50s %s\n" "Fixing /etc/csh.login .............................." "Status: Skip. Reason: Existing"
fi

#Removing the unused username api_pcm from the system. Gold disk user
if [[ $(grep -c api_pcm /etc/passwd) == 1 ]];then
        if [[ -d /home/api_pcm ]];then
                rm -rf /home/api_pcm
        fi
        rmuser -p api_pcm
        printf "%.50s %s\n" "Removing unused users api_pcm .............................." "Status: OK. Reason: Done"
else
        printf "%.50s %s\n" "Removing unused users api_pcm .............................." "Status: Skip. Reason: Non Existing"
fi

###Password complexity and algorithm

##Login Config
#Change the password algorithm to SSHA512
ch_login usw pwd_algorithm=ssha512
#Create home directory on login if not existing, mandatory for LDAP users
ch_login usw mkhomeatlogin=true
#Change the number of second given to a user to enter his password
ch_login usw logintimeout=30


#Change the number of unsuccesfull logins attempts berfore locking up the port for the user to 10
ch_login default logindisable=10
#Change the time for which the disable feature is valid (10 logins for  5min) then the port is locked
ch_login default logininterval=300
#Change the time reactivation of the port that was locked to 15 min (if 15 failed logins for 60sec then unlock the port in 15 min)
ch_login default loginreenable=15
#Change the time between unsuccessful logins to 5 sec (second login 10s, third 15s etc).
ch_login default logindelay=5
#Change the default herald (function cannot pass this argumenti) so a manual change will be done:
chsec -f /etc/security/login.cfg -s default -a "herald=Authorized Users Only \nlogin:"
printf "%.50s %s\n" "Login config, Set herald to a value.............................." "Status: OK. Reason: Done"



##Password Config
#Change the dictionary list file for password checking
#ch_pwd default "dictionlist=/usr/share/dict/words
#Change the minimal alphabetic characters for a password
ch_pwd default minalpha=4
#Change the minimal number of other characters
ch_pwd default minother=2
#Change minimal number of lowercase alphabetical characters in the password
ch_pwd default minloweralpha=3
#Change the minimal number of capital alphabetical characters in the password
ch_pwd default minupperalpha=2
#Change the minimal number of digits in the password
ch_pwd default mindigit=2
#Change the minimal number of special characters in the password
ch_pwd default minspecialchar=1
#Change the minimum number of characters that were no present in the old password
ch_pwd default mindiff=4
#Change the maxim number of repetition of a character in a password
ch_pwd default maxrepeats=2
#Change the minimum lenght of the password
ch_pwd default minlen=12

#User password and login policies
#Change the number of unsuccesful logins before the account is locked
ch_pwd default loginretries=3
#Change the number of passwords that cannot be reused i.e (last passwords)
ch_pwd default histsize=20
#Change the number of weeks the user cannot reuse a password
ch_pwd default histexpire=13
#Change the default umask of the users to 027
ch_pwd default umask=027
#Change the maximum time that a password is valid to 0 (this imlies that the password won't expire)
ch_pwd default maxage=12


###Stop unnecessary services on the system
stop_inetd ftp
stop_inetd telnet
ch_rctcpip sendmail disable all
ch_rctcpip syslogd enable all
#CIS 3.3.20
ch_rctcpip snmpmibd disable all
#CIS 3.3.21
ch_rctcpip aixmibd disable all
#CIS 4.2.13
ch_rctcpip hostmibd disable all

##Stop the writesrv server because we're not going to use it

if [[ $(lsitab writesrv |grep -c wait) == 1 ]];then
        comd="chitab '$(lsitab -a |grep writesrv |sed 's/wait/off/g')'"
        echo $comd > /tmp/itab.sh
        ksh /tmp/itab.sh
        rm -f /tmp/itab.sh
        printf "%.50s %s\n" "Disable writesrv Daemon .............................." "Status: Done. Reason: OK"
        stop_src writesrv
else
        printf "%.50s %s\n" "Disable writesrv Daemon .............................." "Status: Skip. Reason: disabled"
        stop_src writesrv
fi

##Change default system parameters
#Change the maxim length of a username !!!reboot is required for this to take effect
ch_sysparam sys0 max_logname=32


#Set the "root" and "aixmgr" accounts passwords to never expire
if [[ $(lsuser -a maxage root|cut -d "=" -f2) != 0 ]];then
        chuser "maxage=0" root
        printf "%.50s %s\n" "Setup root account never expire .............................." "Status: Done. Reason: OK"
else
        printf "%.50s %s\n" "Setup root account never expire .............................." "Status: Skip. Reason: Existing"
fi

if [[ $(lsuser -a maxage aixmgr|cut -d "=" -f2) != 0 ]];then
        chuser "maxage=0" aixmgr
        printf "%.50s %s\n" "Setup aixmgr account never expire .............................." "Status: Done. Reason: OK"
else
        printf "%.50s %s\n" "Setup aixmgr account never expire .............................." "Status: Skip. Reason: Existing"
fi


#Creating the SVC_PDXCBOOT account for PDXC enrolments
if [[ $(grep -c SVC_PDXCBOOT /etc/passwd) == 0 ]];then
        mkgroup -'A' id='10002' SVC_PDXCBOOT
        mkuser -a id='10002' admin='false' histsize= pgrp='SVC_PDXCBOOT' maxage='0' groups='SVC_PDXCBOOT' home='/home/SVC_PDXCBOOT' shell='/usr/bin/ksh' gecos='PDXC Service User'  SVC_PDXCBOOT
        echo "SVC_PDXCBOOT ALL=(ALL) NOPASSWD: ALL" > /var/sudo/etc/sudoers.d/SVC_PDXCBOOT
        echo 'SVC_PDXCBOOT:{ssha512}06$0m6/8qzM.7lcpLMD$t8V1K2aPuR9tomV51AnTDcNxvcYRiVfvZjVbzB/7uHGNUq9ncQCXzoq3eXzKF3AZoRthNl0SsQD8sAn.myt6..' |chpasswd -c -e
        printf "%.50s %s\n" "Adding SVC_PDXCBOOT user and sudo permissions .............................." "Status: OK. Reason: Done"
        if [[ -d /home/SVC_PDXCBOOT ]];then
                chmod 750 /home/SVC_PDXCBOOT
        fi
else
        printf "%.50s %s\n" "Adding SVC_PDXCBOOT user and sudo permissions .............................." "Status: Skip. Reason: Existing"
fi


#Security Fixes
#HPESSAP0380 - Sendmail configuration file DaemonPortOptions should be pointing to 127.0.0.1 and Privacy options must be set to "goaway"
if [[ $(grep -cw "O DaemonPortOptions=Name=MTA, Addr=127.0.0.1" /etc/sendmail.cf) == 0 || $(grep -cw "O PrivacyOptions=goaway" /etc/sendmail.cf) == 0 ]];then
        echo "s/^O DaemonPortOptions=.*/O DaemonPortOptions=Name=MTA, Addr=127.0.0.1/g" > /tmp/sendmail.sed
        echo "s/^O PrivacyOptions=.*/O PrivacyOptions=goaway/g">> /tmp/sendmail.sed
        cp -p /etc/sendmail.cf /tmp/sendmail.cf
        sed -f /tmp/sendmail.sed /tmp/sendmail.cf > /etc/sendmail.cf
        rm /tmp/sendmail.sed
        rm /tmp/sendmail.cf
        printf "%.50s %s\n" "HPESSAP0380 - Sendmail .............................." "Status: Done. Reason: OK"
else
        printf "%.50s %s\n" "HPESSAP0380 - Sendmail .............................." "Status: Skip. Reason: Existing"
fi

#HPESSAP0374 - FTP Allowed users - All users below UID 200 should be present in the /etc/ftpusers file
lsuser -c ALL | grep -v ^#name | cut -f1 -d: | while read NAME; do
        if [ `lsuser -f $NAME | grep id | cut -f2 -d=` -lt 200 ]; then
                echo $NAME >> /tmp/ftpusers.new
        fi
done
cat /tmp/ftpusers.new > /etc/ftpusers
rm /tmp/ftpusers.new
printf "%.50s %s\n" "HPESSAP0374 - FTP Allowed users .............................." "Status: Done. Reason: OK"


#HPESSAP0381 - Are at.allow file permissions set to 400 or stricter and cron.allow
chmod 400 /var/adm/cron/at.allow
chmod 400 /var/adm/cron/cron.allow
rm -f /var/adm/cron/at.deny
chown root:sys /var/adm/cron/at.allow
chown root:sys /var/adm/cron/cron.allow
printf "%.50s %s\n" "HPESSAP0381 - Configuring CRON administration file permissions .............................." "Status: Done. Reason: OK"

#HPESSAP0572 - The file permission for /var/adm/wtmp or /var/adm/wtmpx are adm:adm:644
if [[ $(perl -e'printf "%o\n",(stat shift)[2] & 07777' /var/adm/wtmp) != 644 ]]; then
        chmod 644 /var/adm/wtmp
        printf "%.50s %s\n" "HPESSAP0572 - Change wtmp file permissions to 644 .............................." "Status: Done. Reason: OK"
else
        printf "%.50s %s\n" "HPESSAP0572 - Change wtmp file permissions to 644 .............................." "Status: Skip. Reason: Existing"
fi

#HPESSAP0370 - Does the system contain any SGID System Executables - Remove all SGID bits from the binaries
#find / ! -fstype jfs2 -prune -o -type f -perm -2000 -print > /tmp/sgid.list # this will display all files that have the SGID enabled
#if [[ $(wc -l /tmp/sgid.list|awk '{print $1}') != 0 ]];then
#       while read line;do
#               chmod g-s $line
#       done < /tmp/sgid.list
#       printf "%.50s %s\n" "HPESSAP0370 - Remove SGID from files .............................." "Status: OK. Reason: Done"
#else
#       printf "%.50s %s\n" "HPESSAP0370 - Remove SGID from files .............................." "Status: Skip. Reason: NO files present"
#fi
#rm /tmp/sgid.list


#HPESSAP0370 - Does the system contain any SUID System Executables - Remove all SUID bits from binaries
#find / ! -fstype jfs2 -prune -o -type f -perm -4000 -print > /tmp/suid.list # this will display all files that have the SGID enabled
#if [[ $(wc -l /tmp/suid.list|awk '{print $1}') != 0 ]];then
#       while read line;do
#               chmod u-s $line
#       done < /tmp/suid.list
#       chmod u+s /usr/bin/sudo
#       printf "%.50s %s\n" "HPESSAP0370 - Remove SUID from files .............................." "Status: OK. Reason: Done"
#else
#       printf "%.50s %s\n" "HPESSAP0370 - Remove SUID from files .............................." "Status: Skip. Reason: No files present"
#fi
#rm /tmp/suid.list

#HPESSAP0579 - "unowned" files and directories
find /usr/lpp/bos/bos.rte.install/7.2.3.19 -group 300 > /tmp/unowned.list
find /usr/lpp/bos.net/inst_root/var/snapp -group 177 >> /tmp/unowned.list
find /usr/lpp/bos.net/inst_root/etc -group 987 >> /tmp/unowned.list
if  [[ $(wc -l /tmp/unowned.list|awk '{print $1}') != 0 ]];then
        for i in $(cat /tmp/unowned.list);do
                if [ -f $i ];then
                        chown root:system $i
                elif [ -d $i ];then
                        chown root:system $i
                fi
        done
        printf "%.50s %s\n" "HPESSAP0579 - unowned files change to root:system .............................." "Status: OK. Reason: Done"
else
        printf "%.50s %s\n" "HPESSAP0579 - unowned files change to root:system .............................." "Status: Skip. Reason: No files present"
fi
rm /tmp/unowned.list

#HPESSAP0373 - hosts.equiv file exist move the file to hostst.equiv.gld
if [ -f /etc/hosts.equiv ];then
        mv /etc/hosts.equiv /etc/hosts.equiv.gld
        printf "%.50s %s\n" "HPESSAP0373 - hosts.equiv move .............................." "Status: OK. Reason: Done"
else
        printf "%.50s %s\n" "HPESSAP0373 - hosts.equiv move .............................." "Status: Skip. Reason: Not existing"
fi

#HPESSAP0368 - Setting up a default UMASK for all users in the /etc/security/.profile file, although it's not necessary and can cause issues on later stages
if [[ $(grep -cwi "umask 027" /etc/security/.profile) == 0 ]];then
        echo "umask 027" >> /etc/security/.profile
        printf "%.50s %s\n" "HPESSAP0368 - umask 027 /etc/security/.profile .............................." "Status: OK. Reason: Done"
else
        printf "%.50s %s\n" "HPESSAP0368 - umask 027 /etc/security/.profile .............................." "Status: Skip. Reason: Existing"
fi

#HPESSAP0568 - Do any . or group/world-writable directories not exist in root $PATH? /usr/ucb has a group +w so remove it
perm=$(perl -e'printf "%o\n",(stat shift)[2] & 07777' /usr/ucb);
if [[ $perm == 775 ]];then
        chmod 755 /usr/ucb
        printf "%.50s %s\n" "HPESSAP0568 - changing the perms of /usr/ucb .............................." "Status: OK. Reason: Done"
else
        printf "%.50s %s\n" "HPESSAP0568 - changing the perms of /usr/ucb .............................." "Status: Skip. Reason: Not Required"
fi

#HPESSAP0373 - Verify rhost entries /etc/pam.conf - remove the entries that are using the pam_rhosts_auth module from the /etc/pam.conf
if [[ $(grep -wc "pam_rhosts_auth$" /etc/pam.conf) != 0 ]]; then
        echo "/pam_rhosts_auth$/d" > /tmp/pam.sed
        cp -p /etc/pam.conf /tmp/pam.conf
        sed -f /tmp/pam.sed /tmp/pam.conf > /etc/pam.conf
        rm -f /tmp/pam.sed
        rm -f /tmp/pam.conf
        printf "%.50s %s\n" "HPESSAP0373 - Remove the pam_rhosts_auth .............................." "Status: OK. Reason: Done"
else

        printf "%.50s %s\n" "HPESSAP0373 - Remove the pam_rhosts_auth .............................." "Status: Skip. Reason: Not Required"
fi

#HPESSAP0363 - The /etc/filesystems should not be set to group/world-writeable
if [[ $(perl -e'printf "%o\n",(stat shift)[2] & 07777' /etc/filesystems) != 644 ]];then
        chmod 644 /etc/filesystems
        printf "%.50s %s\n" "HPESSAP0363 - Fix /etc/filesystems to 644 .............................." "Status: OK. Reason: Done"
else
        printf "%.50s %s\n" "HPESSAP0363 - Fix /etc/filesystems to 644 .............................." "Status: Skip. Reason: Not Required"
fi

###Setting Kernel Parameters and stopping the unnecessary inittab services
#CIS 3.3.3
rm_itab piobe
#CIS 3.3.20
rm_itab qdaemon
rm_itab cimservices
rm_itab pconsole


###CIS 3.6.1
ch_kernel_p ipsrcrouteforward 0 both no
###CIS 3.6.2
ch_kernel_p ipignoreredirects 1 both no
###CIS 3.6.3
ch_kernel_p clean_partial_conns 1 both no
###CIS 3.6.4
ch_kernel_p ipsrcroutesend 0 both no
###CIS 3.6.6
ch_kernel_p ipsendredirects 0 both no
###CIS 3.6.7
ch_kernel_p ip6srcrouteforward 0 both no
###CIS 3.6.9
ch_kernel_p tcp_pmtu_discover 0 both no
###CIS 3.6.12
ch_kernel_p udp_pmtu_discover 0 both no
###CIS 3.6.15
ch_kernel_p tcp_tcpsecure 7  both no
###CIS 3.6.16
ch_kernel_p sockthresh 60 both no
###CIS 3.6.17
ch_kernel_p rfc1323 1 both no
###CIS 3.6.18
ch_kernel_p tcp_sendspace 262144 both no
###CIS 3.6.19
ch_kernel_p tcp_recvspace 262144 both no
###CIS 3.6.20
ch_kernel_p tcp_mssdflt 1448 both no
###CIS 3.6.21
ch_kernel_p nfs_use_reserved_ports 1 both nfso
ch_kernel_p portcheck 1 both nfso


###Fixing the /etc/ssh/sshd_config file paramters with a template (only for initial use), will replace everything so use with caution
cat > /etc/ssh/sshd_config << EOF
#       $OpenBSD: sshd_config,v 1.101 2017/03/14 07:19:07 djm Exp $

# This is the sshd server system-wide configuration file.  See
# sshd_config(5) for more information.

# This sshd was compiled with PATH=/usr/bin:/bin:/usr/sbin:/sbin

# The strategy used for options in the default sshd_config shipped with
# OpenSSH is to specify options with their default value where
# possible, but leave them commented.  Uncommented options override the
# default value.

#Port 22
AddressFamily inet
ListenAddress 0.0.0.0
#ListenAddress ::
Protocol 2

#HostKey /etc/ssh/ssh_host_rsa_key
#HostKey /etc/ssh/ssh_host_dsa_key
#HostKey /etc/ssh/ssh_host_ecdsa_key
#HostKey /etc/ssh/ssh_host_ed25519_key

# Ciphers and keying
#RekeyLimit default none

# Logging
#SyslogFacility AUTH
#LogLevel INFO

# Authentication:

#LoginGraceTime 2m
PermitRootLogin no
#StrictModes yes
MaxAuthTries 4
#MaxSessions 10

#PubkeyAuthentication yes

# The default is to check both .ssh/authorized_keys and .ssh/authorized_keys2
# but this is overridden so installations will only check .ssh/authorized_keys
AuthorizedKeysFile      .ssh/authorized_keys

#AuthorizedPrincipalsFile none

#AuthorizedKeysCommand none
#AuthorizedKeysCommandUser nobody

# For this to work you will also need host keys in /etc/ssh/ssh_known_hosts
HostbasedAuthentication no
# Change to yes if you don't trust ~/.ssh/known_hosts for
# HostbasedAuthentication
#IgnoreUserKnownHosts no
# Don't read the user's ~/.rhosts and ~/.shosts files
IgnoreRhosts yes

# To disable tunneled clear text passwords, change to no here!
#PasswordAuthentication yes
PermitEmptyPasswords no

# Change to no to disable s/key passwords
#ChallengeResponseAuthentication yes

# Kerberos options
#KerberosAuthentication no
#KerberosOrLocalPasswd yes
#KerberosTicketCleanup yes
#KerberosGetAFSToken no

# GSSAPI options
#GSSAPIAuthentication no
#GSSAPICleanupCredentials yes

#GSSAPIStrictAcceptorCheck yes
#GSSAPIKeyExchange no

# Set this to 'yes' to enable PAM authentication, account processing,
# and session processing. If this is enabled, PAM authentication will
# be allowed through the ChallengeResponseAuthentication and
# PasswordAuthentication.  Depending on your PAM configuration,
# PAM authentication via ChallengeResponseAuthentication may bypass
# the setting of "PermitRootLogin without-password".
# If you just want the PAM account and session checks to run without
# PAM authentication, then enable this but set PasswordAuthentication
# and ChallengeResponseAuthentication to 'no'.
#UsePAM no
#UsePrivilegeSeparation yes

#AllowAgentForwarding yes
#AllowTcpForwarding yes
#GatewayPorts no
#X11Forwarding no
#X11DisplayOffset 10
#X11UseLocalhost yes
#PermitTTY yes
#PrintMotd yes
#PrintLastLog yes
#TCPKeepAlive yes
#UseLogin no
#PermitUserEnvironment no
#Compression delayed
#ClientAliveInterval 0
#ClientAliveCountMax 3
#UseDNS no
#PidFile /var/run/sshd.pid
#MaxStartups 10:30:100
#PermitTunnel no
#ChrootDirectory none
#VersionAddendum none

# no default banner path
Banner /etc/motd

#Ciphers offered
Ciphers aes128-ctr,aes192-ctr,aes256-ctr

# override default of no subsystems
Subsystem       sftp    /usr/sbin/sftp-server

# Example of overriding settings on a per-user basis
#Match User anoncvs
#       X11Forwarding no
#       AllowTcpForwarding no
#       PermitTTY no
#       ForceCommand cvs server
EOF
message "SSHD Fix" "Replacing the existing sshd_config file with a template" "Done" "OK"
stopsrc -s sshd;startsrc -s sshd;
message "SSHD Fix" "Restarting the sshd daemon" "Done" "OK"

if [[ $(grep -c "^Protocol[[:blank:]]" /etc/ssh/ssh_config) == 0 ]];then
        echo "Protocol 2" >> /etc/ssh/ssh_config
        message "SSH Client" "Forceing Protocol 2" "Done" "OK"
else
        message "SSH Client" "Forceing Protocol 2" "Skip" "Existing"
fi

###Fixing the file permissions as per CIS checks
#CIS 3.3.53
chmod 644 /etc/inetd.conf
chown root:system /etc/inetd.conf
#CIS 3.4.1
chmod 000 /usr/bin/rcp
chmod 000 /usr/bin/rlogin
chmod 000 /usr/bin/rsh
#CIS 3.4.2
chmod 000 /usr/sbin/rlogind
chmod 000 /usr/sbin/rshd
chmod 000 /usr/sbin/tftpd
#CIS 4.2.18
chmod 600 /etc/ssh/sshd_config
#CIS 4.3.2
chown root:system /etc/sendmail.cf
chmod 640 /etc/sendmail.cf
#CIS 4.3.3
chown root:system /var/spool/mqueue
chmod 700 /var/spool/mqueue
#CIS 4.11.1
chown -R root:security /etc/security
chmod u=rwx,g=rx,o= /etc/security
chmod -R go-w,o-rx /etc/security
#CIS 4.11.4
chown -R root:audit /etc/security/audit
chmod u=rwx,g=rx,o= /etc/security/audit
chmod -R u=rw,g=r,o= /etc/security/audit/*
#CIS 4.11.8
chmod -R o= /var/spool/cron/crontabs
chmod ug=rwx,o= /var/spool/cron/crontabs
chgrp -R cron /var/spool/cron/crontabs
#CIS 4.11.12
chmod o-rw /var/adm/ras/*
#CIS 4.11.13
chmod 640 /var/ct/RMstart.log
chown root:system /var/ct/RMstart.log
#CIS 4.11.15
chmod o-rw /var/tmp/hostmibd.log
#CIS 4.11.16
chown root:system /smit.log
chmod 640 /smit.log
#CIS 4.11.17
chown adm:adm /var/adm/sa
chmod u=rwx,go=rx /var/adm/sa

message "File Permissions" "CIS" "Done" "OK"
###Packages removal
#CIS 4.6.1
installp -u bos.net.nis.client >/dev/null 2>&1
message "Removing packages" "NIS Client" "Done" "OK"

###Remove Default limits for core and core_hard
#CIS 3.7.8
chsec -f /etc/security/limits -s default -a core=0 -a core_hard=0
