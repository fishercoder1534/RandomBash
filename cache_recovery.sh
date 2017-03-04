#!/bin/bash
SECONDS=0
set -e # -e  Exit immediately if a command exits with a non-zero status.

# Prerequisites:
#    Install AWS CLI

which aws > /dev/null
if [[ $? -ne 0 ]]; then
    echo "Need to install aws command line https://aws.amazon.com/cli/"
    exit 1
fi
aws_version=`aws --version`
echo "Using AWS-CLI with version ${aws_version}"

PROFILE1="PROFILE1"
aws configure set region ap-northeast-2
aws configure set output json
echo -e "\n~/.aws/config:"
cat ~/.aws/config

aws configure --profile ${PROFILE1} set aws_access_key_id XXXXXX
aws configure --profile ${PROFILE1} set aws_secret_access_key XXXXXX
echo -e "\n~/.aws/credentials:"
cat ~/.aws/credentials

#Find all snapshot ARNs in S3, sort them, find the most recent ones, and concatenate them together, and then pass it into the create command
S3_BUCKET_NAME="SOME-NAME"
ALL_FILES=`aws s3 ls s3://${S3_BUCKET_NAME} | sort -nr` #list all files in this S3 bucket, sort them in reverse order based on string nummerical value of their filenames

first_rbd_file=`aws s3 ls s3://${S3_BUCKET_NAME} | sort -nr | head -1`
for word in ${first_rbd_file}; do 
	prefix=$word # let it overwrite to variable ${prefix} to get the last one which is the file name
done
# prefix=${prefix:0:17} # the first 17 digits should be the same for one set of .rbd files which is its date, like this: "2017-02-20-14-13-" or 
prefix=${prefix:0:31}
echo "prefix: ${prefix}"

# find all files with this prefix
backup_files=`aws s3 ls s3://${S3_BUCKET_NAME} | sort -nr | grep ${prefix}`
backup_files_array=()
i=0
for word in ${backup_files}; do
	backup_files_array[$i]=$word
	i=$((i+1))
done

# concatenate all .rbd files into one argument in this format: "--snapshot-arns arn:aws:s3:::search-mate-cache/2017-02-19-23-00-0001.rdb"
array_length=${#backup_files_array[@]}
snapshot_arns_arg="--snapshot-arns"
echo ${snapshot_arns_arg}
space=" "
S3_arn="arn:aws:s3:::"${S3_BUCKET_NAME}"/"
all_snaps=""
for ((i=3; i < ${array_length}; i+=4)) #every 4th element is the filename, all other elements are metadata of this file, so increment counter by 4
    do
    # temp=${space}${snapshot_arns_name}${space}${S3_arn}${backup_files_array[$i]}
    temp=${space}${S3_arn}${backup_files_array[$i]}
    all_snaps=${all_snaps}${temp}
    done
snapshot_arns_arg=${snapshot_arns_arg}${all_snaps}
echo "snapshot_arns_arg: ${snapshot_arns_arg}"


now="$(date +'%Y-%m-%d-%H-%M')"
printf "Current date in format %s\n" "$now"

# NEW_REDIS_CLUSTER_ID='mat-'$now
NEW_REDIS_CLUSTER_ID='cach-reco'
echo ${#NEW_REDIS_CLUSTER_ID}
echo "NEW_REDIS_CLUSTER_ID: ${NEW_REDIS_CLUSTER_ID}"
NUM_NODE_GROUPS=2 #we have two shards in dev zone, so there will be two snapshots .rdb files, so we'll need two node groups
NEW_CACHE_CLUSTER_DESCRIPTION="cache-recovery"
aws elasticache create-replication-group --replication-group-id ${NEW_REDIS_CLUSTER_ID} --num-node-groups ${NUM_NODE_GROUPS} \
${snapshot_arns_arg} --cache-node-type cache.m4.xlarge --cache-parameter-group default.redis3.2.cluster.on --engine redis --engine-version 3.2.4 --replication-group-description ${NEW_CACHE_CLUSTER_DESCRIPTION} --cache-subnet-group-name search-cache-dev \
--node-group-configuration "ReplicaCount=1,Slots=0-8999,PrimaryAvailabilityZone='ap-northeast-2a',ReplicaAvailabilityZones='ap-northeast-2c'" \
"ReplicaCount=1,Slots=9000-16383,PrimaryAvailabilityZone='ap-northeast-2c',ReplicaAvailabilityZones='ap-northeast-2a'"


CREATING_STATUS="creating"
AVAILABLE_STATUS="available"
while true; do
    status=`aws elasticache describe-replication-groups --replication-group-id ${NEW_REDIS_CLUSTER_ID} | grep -m 1 "Status" | cut -d: -f2 | sed 's/,/ /g' | xargs`
    echo "${status}"
    if [ "${status}" = "${CREATING_STATUS}" ]; then
        echo "${status}"
    elif [[ ${status} = "${AVAILABLE_STATUS}" ]]; then
        echo "${NEW_REDIS_CLUSTER_ID} is now available"
        break;
    fi
    sleep 5
done
duration=$SECONDS
echo "created a new Redis cluster: ${NEW_REDIS_CLUSTER_ID}"
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."



