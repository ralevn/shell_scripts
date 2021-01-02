#!/bin/ksh93
# ------------------------------------------------------------------------------
# This script updates all adapter microcode to the latest levels available in /usr/lib/microcode 
# ------------------------------------------------------------------------------


function logerror
{ $FULLDEBUG
  RC=1
  if   [[ $1 == -i ]]; then
       shift 1
       print -- "           $*"
  else
       print -- "E $( date +%T ) $ME: $*"
  fi   | alog -t console
  return 1
}

function logwarning
{ $FULLDEBUG
  RC=1
  if   [[ $1 == -i ]]; then
       shift 1
       print -- "           $*"
  else
       print -- "W $( date +%T ) $ME: $*"
  fi   | alog -t console
  return 1
}

function loginfo
{ $FULLDEBUG
  if   [[ $1 == -i ]]; then
       shift 1
       print -- "           $*"
  else
       print -- "I $( date +%T ) $ME: $*"
  fi   | alog -t console
  return 0
}

function logbulk
{ $FULLDEBUG
  sed 's/^/     /' | alog -t console
  return 0
}


myhelp()
{ $FULLDEBUG

  cat <<EOF

  Syntax

    $ME [ -r ] [ -h ]

  Description
     Updates adapter microcode to the latest level
     found in /usr/lib/microcode.     
     $ME is invoked by firstboot following multibos Stack update
     
     WARNING: Network disruptions may occur if $ME is used otherwise. 

  Flags

    -r   Unconfigure network devices if necessary

    -h   Prints this help

EOF
}


ucode_list_updatable()
{
     loginfo "Checking for applicable updates"
     /usr/lpp/diagnostics/bin/umcode_latest -l > /tmp/umcode.$$
     grep -q 'here are no resources' < /tmp/umcode.$$
     if [[ $? -eq 0 ]] ; then
          loginfo "Microcode is already at the latest Factory levels"
          return 1
     else 
          cat /tmp/umcode.$$ | logbulk
          return 0
     fi
}


filter_ethernet()
{
     awk '/^(ent|hba)[0-9]+/ {print $1}'
}

filter_fiberchannel()
{
     awk '/^fcs[0-9]+/ {print $1}'
}

ucode_update()
{
     while read -r -- 
     do
     loginfo "Updating $REPLY ..."
     /usr/sbin/diag -c -d $REPLY -T "download -s /etc/microcode -l latest -f" | logbulk
     done
}

lsdevEntAndHba()
{ lsdev -C -c adapter -F name | \
  awk '$1 ~ /^ent/ { print
                     system("lsdev -CF parent -l " $1) } ' | \
  grep -E -- "^(ent|hba)[0-9]+" | sort
  return 0
}

lsdevEnAndEt()
{ lsdev -CF name | awk ' /^e[tn][0-9]+/ ' | sort
  return 0
}

lsAllNetDevices()
{ $FULLDEBUG
  #
  # keep order: first children then parents
  #

  lsdevEnAndEt

  { lsdev -C -c adapter -t eth     -s vlan -F name
    lsdev -C -c adapter -t sea     -s pseudo -F name
    lsdev -C -c adapter -t ibm_ech -s pseudo -F name
    lsdevEntAndHba

  } | awk ' !x[$1]++ '

  return 0
}

function rmdevAllEnt
{ lsAllNetDevices | \
while read netdev
do
  rmdev -l $netdev
done
return 0
}


# ------------------------------------------------------------------------------
# all output goes to the boot log
# alog -t boot -o
# ------------------------------------------------------------------------------
ME="${0##*/}"
RC=0
RMDEV=
e_file=/etc/globe.aix.ucode.update.enabled.
a_FLAG=
skip_cfgmgr=

while getopts :aedrh OPT; do

      case $OPT in
           a     ) RMDEV=1 ; a_FLAG=1       ;; ## Auto flag used in rc.shutdown    
           r     ) RMDEV=1    ;;
           e     ) touch $e_file ; exit 0   ;; ## just enable it to run next time rc.shutdown is executed   
           d     ) rm -f $e_file ; exit 0   ;; ## disable execution under rc.shutdown is executed   
           h     ) myhelp; exit 0     ;;
      esac
done
shift $(( OPTIND -1 ))

if [[ -n $a_FLAG ]] ; then
     if [[ -f $e_file ]] ; then
          loginfo "Microcode update of PCI adapters is ON."
     else
          loginfo "Microcode update of PCI adapters is not enabled."
          exit 0
     fi
     skip_cfgmgr=1
     rm -f $e_file
fi

if ucode_list_updatable; then
     loginfo "Running microcode update for eligible PCI adapters"
     cat /tmp/umcode.$$ | filter_fiberchannel | ucode_update
     
     ENT=$(cat /tmp/umcode.$$ | filter_ethernet)
     if [[ -n $ENT ]] ; then
          if [[ -n $RMDEV ]] ; then
               logwarning "Networking will be disabled for microcode update."
               logwarning "Your session may be lost"
               sleep 2

               rmdevAllEnt
               rmdevAllEnt # workaround for what looks like a timing issue / race condition

          fi
          
          cat /tmp/umcode.$$ | filter_ethernet | ucode_update
          
          [[ -z $skip_cfgmgr ]] && { loginfo "Running cfgmgr ..." ; cfgmgr -S; mkdev -l inet0 ; } 
     fi     
     

     loginfo "Post-update verification"
     ucode_list_updatable
     [[ -z $a_FLAG ]] && logwarning "System reboot is highly recommended !!!"
fi
loginfo "exiting"
exit 0
