#!/bin/bash

function psqlcmd () {
        db=$1
        qry=$2
        psql -U postgres -h localhost -d $db -c "\t" -c "\pset border 0" -c "$qry" -q
}



CLUST_NUMBER=$(psqlcmd "platform" "select COUNT(*) from cluster")
echo "Number of Clusters:  $CLUST_NUMBER"


# Queries to take Bundle Ids:
QR_NSX_BUND_ID="SELECT upgrade_spec_json::jsonb->>'bundleId'
               FROM upgrade
               WHERE upgrade_spec_json::jsonb->'nsxtUpgradeUserInputSpecs' IS NOT NULL
               ORDER BY start_time DESC
               LIMIT 1"
BUNDLE_ID=$(psqlcmd "lcm" "$QR_NSX_BUND_ID"|grep -v "^$")
QR_CL_ID_UPDSTS="SELECT upgrade_status, upgrade_spec_json::jsonb->'nsxtUpgradeUserInputSpecs'->0->>'nsxtId'
                 FROM upgrade
                 WHERE upgrade_spec_json::jsonb->'nsxtUpgradeUserInputSpecs' is not null and bundle_id='$BUNDLE_ID'
                 LIMIT $CLUST_NUMBER"

#Function to fill in the array with cluster nsx ids and names
function cluster_ids () {

	psqlcmd "lcm" "$QR_CL_ID_UPDSTS"
}

while true
do
	date
	echo
	cluster_ids
	echo;echo "presee ctrl+C to exit"
	sleep 10
	clear
done

