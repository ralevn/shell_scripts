#!/bin/bash

function psqlcmd () {
        db=$1
        qry=$2
        psql -U postgres -h localhost -d $db -c "\t" -c "\pset border 0" -c "$qry" -q
}



CLUST_NUMBER=$(psqlcmd "platform" "select COUNT(*) from cluster")
echo "Number of Clusters:  $CLUST_NUMBER"


# Queries to take Bundle Ids:
QR_VX_BUND_ID="SELECT bundle_id
               FROM upgrade
               WHERE bundle_id like 'VXRAIL7%' and start_time IS NOT NULL
               ORDER BY start_time DESC
               LIMIT 1"
BUNDLE_ID=$(psqlcmd "lcm" "$QR_VX_BUND_ID"|grep -v "^$")
QR_CL_ID_UPDSTS="SELECT upgrade_status,upgrade_spec_json::jsonb->'esxClusterUpgradeSpecs'->0->>'clusterId'
                 FROM upgrade
                 WHERE upgrade_spec_json::jsonb->'esxClusterUpgradeSpecs'->0->>'clusterId' <> '' and bundle_id='$BUNDLE_ID'
                 LIMIT $CLUST_NUMBER"


#Function to fill in the array with cluster nsx ids and names
function cluster_ids () {

	psqlcmd "lcm" "$QR_CL_ID_UPDSTS"
}

# create assiciative array with cluster IDs and NAMEs
declare -A clusters
while read id name
do
        clusters["$id"]="$name"
done < <(psqlcmd "platform" "select id,name from cluster" |grep -v "^$")

#create array with cluster ids and upgrade status
declare -A clusUpgradeStat
while read stat id
do
        clusUpgradeStat["$id"]="$stat"
done < <(cluster_ids |grep -v "^$")


function main () {
	echo
        while true
        do
                #clear
                date;echo "================="
                for k in "${!clusUpgradeStat[@]}"; do
                        echo ${clusters[$k]} :: ${clusUpgradeStat[$k]};
                done
                echo "Ctrl+C to Exit"
                sleep 10
        done
}

# The following section is for debug and test purpose
echo "Test things:"
echo;echo "check function cluster_ids with bundid VXRAIL7-0-101-26770072DL101581_VxRail-7-0-101-Composite-Upgrade-Slim-Package-for-7-0-x-zip"
cluster_ids "VXRAIL7-0-101-26770072DL101581_VxRail-7-0-101-Composite-Upgrade-Slim-Package-for-7-0-x-zip"

echo;echo -n "The Bundle Id of the last upgrade: " $BUNDLE_ID

echo;echo "iterate k and v over clusters"
for k in "${!clusters[@]}"; do echo $k :: ${clusters[$k]}; done

echo;echo "iterate k and v over clusUpgradeStat"
for k in "${!clusUpgradeStat[@]}"; do echo Key $k ::  Val ${clusUpgradeStat[$k]}; done

echo;echo "iterate v over clusters"
for v in "${clusters[@]}"; do echo $v; done


echo "actual execution clear commented"
main
