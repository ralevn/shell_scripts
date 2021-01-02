#!/usr/bin/ksh

echo hallo | awk '
        {
                #
                # fcs#
                #
                printf("%-8s %-8s %-8s %-10s %-16s %-6s %-16s %-4s %-4s", "FCS", "FSCSI", "MODEL", "FW", "WWN", "LOC", "PHYSICAL", "LINK", "CMDS")
                #
                # fscsi#
                #
                # printf(" %-6s %-10s %-12s %-8s %-8s %-4s %-4s\n", "ATTACH", "DYNTRK", "RECOVERY", "NPORT ID", "VENDOR", "DOM", "PORT")
                printf(" %-6s %-10s %-12s %-8s\n", "ATTACH", "DYNTRK", "RECOVERY", "NPORT ID")
        }
'
lsdev -Ct efscsi -F name | sort | while read FSCSI
do
        FCS=$(lsdev -Cl $FSCSI -F parent)
        (lsattr -El $FSCSI -F "attribute value" && lscfg -vpl $FCS && lsattr -El $FCS -F "attribute value") |\
        awk -v fcs=$FCS -v fscsi=$FSCSI '

        BEGIN {
                cmd=sprintf("lsdev -Cl %s -F location", fcs)
                cmd | getline loc
        }
        #
        # lscfg -vpl fcs#
        #
        /Network Address/ {
                wwn=substr($0,37)
        }
        /ZA/ {
                fw=substr($0,37)
        }
        /Model/ {
                model=$2
        }
        /Physical Location:/ {
                physical_loc=$3
        }
        #
        # lsattr -El fcs# -F "attribute value"
        #
        /init_link/ {
                initlink=$NF
        }
        /num_cmd_elems/ {
                cmds=$NF
        }
        #
        # lsattr -El fscsi# -F "attribute value"
        #
        /attach/ {
                attach=$NF
        }
        /dyntrk/ {
                dyntrk=sprintf("dyntrk=%s", $NF)
        }
        /fc_err_recov/ {
                fc_err_recov=$NF
        }
        /scsi_id/ {
                nport=$NF

        #       if (attach == "switch") {
        #               switch_type=toupper(substr(nport,7,2))
        #               if (switch_type == "13") {
        #                       switch_vendor="McData"
        #               } else {
        #                       switch_vendor="Brocade"
        #               }
        #
        #               domain=toupper(substr(nport,3,2))
        #               cmd=sprintf("echo \"ibase=16; %s\" | bc", domain)
        #               cmd | getline domain
        #
        #
        #               port=toupper(substr(nport,5,2))
        #               cmd=sprintf("echo \"ibase=16; %s\" | bc", port)
        #               cmd | getline port
        #
        #               if (switch_type == "McData") {
        #                       domain=domain-96
        #                       port=port-4
        #               }
        #
        #       } else {
        #               domain="-"
        #               port="-"
        #       }

        }
        END {
                #
                # fcs#
                #
                printf("%-8s %-8s %-8s %-10s %-16s %-6s %-16s %-4s %-4s", fcs, fscsi, model, fw, wwn, loc, physical_loc, initlink, cmds)
                #
                # fscsi#
                #
                # printf(" %-6s %-10s %-10s %-8s %-8s %-4s %-4s\n", attach, dyntrk, fc_err_recov, nport, switch_vendor, domain, port)
                printf(" %-6s %-10s %-12s %-8s\n", attach, dyntrk, fc_err_recov, nport)
        }
        '
done
