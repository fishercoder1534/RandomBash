#!/bin/bash

set -e # -e  Exit immediately if a command exits with a non-zero status.

# Prerequisites:
#    Install AWS CLI

which aws > /dev/null
if [[ $? -ne 0 ]]; then
    echo "Need to install aws command line https://aws.amazon.com/cli/"
    exit 1
fi
pip install awscli --upgrade --user #make sure awscli is using the latest version, otherwise some commands don't work
aws_version=`aws --version`
echo "Using AWS-CLI with version ${aws_version}"

# Step 1: record timestamp that I'm about to start snapshot
timestamp=$(date +%s)
echo ${timestamp}

# Step 2: attempt to make snapshot until we successfully make it
SECONDS=0
now="$(date +'%Y-%m-%d-%H-%M')"
printf "Current date in format %s\n" "$now"
SNAPSHOT_NAME="cach-"${now}
echo "SNAPSHOT_NAME is: ${SNAPSHOT_NAME}"
REPLICATION_GROUP_ID="cach"
aws elasticache create-snapshot --replication-group-id ${REPLICATION_GROUP_ID} --snapshot-name ${SNAPSHOT_NAME}

# Wait for the image to get created
CREATING_STATUS="creating"
echo ${CREATING_STATUS}
AVAILABLE_STATUS="available"
while true; do
    status=`aws elasticache describe-snapshots --snapshot-name ${SNAPSHOT_NAME} | grep "SnapshotStatus" | cut -d: -f2 | sed 's/,/ /g' | xargs` #xargs to remove trailing empty spaces
    if [ "${status}" = "${CREATING_STATUS}" ]; then
        echo "${status}"
    elif [[ ${status} = "${AVAILABLE_STATUS}" ]]; then
        echo "${SNAPSHOT_NAME} is now available"
        break;
    fi
    sleep 5
done

duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed to create-snapshot."

#copy these snapshots to S3
S3_BUCKET_NAME="cache"
aws elasticache copy-snapshot --source-snapshot-name ${SNAPSHOT_NAME} --target-snapshot-name ${SNAPSHOT_NAME} --target-bucket ${S3_BUCKET_NAME}

# These manual backups/snapshots don't have retention limits and will never be deleted by ElastiCache, so we'll have to manually delete them, otherwise they'll pile up ...
IFS=$'\n'
snapshots_names=($(aws elasticache describe-snapshots --replication-group-id search-mate-cach | grep "SnapshotName" | cut -d: -f2 | sed 's/,/ /g' | sed 's/"/ /g'))
unset IFS
for name in "${snapshots_names[@]}";
do
    if [[ "${name}" -eq "${SNAPSHOT_NAME}" ]];then
        echo "this is the newly created snapshot: ${SNAPSHOT_NAME}"
        continue
    else
        aws elasticache delete-snapshot --snapshot-name ${name}
        echo "deleting this snapshot${name}"
    fi
done



