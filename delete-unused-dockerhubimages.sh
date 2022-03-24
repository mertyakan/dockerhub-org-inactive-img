#!/bin/bash

set -e

# set username and password
UNAME="mertyakan"
UPASS="pass"
ORG="mnmtech"
# get token to be able to talk to Docker Hub
TOKEN=$(curl -s -H "Content-Type: application/json" -X POST -d '{"username": "'${UNAME}'", "password": "'${UPASS}'"}' https://hub.docker.com/v2/users/login/ | jq -r .token)

# get list of namespaces accessible by user (not in use right now)
#NAMESPACES=$(curl -s -H "Authorization: JWT ${TOKEN}" https://hub.docker.com/v2/repositories/namespaces/ | jq -r '.namespaces|.[]')

#echo $TOKEN
echo
# get list of repos for that user account
echo "List of Repositories in ${ORG} Docker Hub account"
sleep 5
REPO_LIST=$(curl -s -H "Authorization: JWT ${TOKEN}" https://hub.docker.com/v2/repositories/${ORG}/?page_size=10000 | jq -r '.results|.[]|.name')
echo $REPO_LIST
echo
# build a list of all images & tags
for i in ${REPO_LIST}
do
  # get tags for repo
  IMAGE_TAGS=$(curl -s -H "Authorization: JWT ${TOKEN}" https://hub.docker.com/v2/repositories/${ORG}/${i}/tags/?page_size=10000 | jq -r '.results|.[]|.name')

  # build a list of images from tags
  for j in ${IMAGE_TAGS}
  do
    # add each tag to list
    FULL_IMAGE_LIST="${FULL_IMAGE_LIST} ${ORG}/${i}:${j}"
      
  done
done

# output list of all docker images
echo
echo "List of all docker images in ${ORG} Docker Hub account"
sleep 10
for i in ${FULL_IMAGE_LIST}
do
  echo ${i}
done

sleep 10
echo
echo "Identifying and deleting images which are older than 50 days in ${ORG} docker hub account"
sleep 10
for i in ${REPO_LIST}

#NOTE!!! For deleting Specific repositories images please include only those repositories in for loop  like below for loop which has repos mygninx and mykibana 
#for i in  mynginx mykibana 

do
  # get tags for repo
  echo
  echo "Looping Through $i repository in ${ORG} account"
  IMAGE_TAGS=$(curl -s -H "Authorization: JWT ${TOKEN}" https://hub.docker.com/v2/repositories/${ORG}/${i}/tags/?page_size=10000 | jq -r '.results|.[]|.name')

  # build a list of images from tags
  for j in ${IMAGE_TAGS}
  do
      echo
      # add last_updated_time
    updated_time=$(curl -s -H "Authorization: JWT ${TOKEN}" https://hub.docker.com/v2/repositories/${ORG}/${i}/tags/${j}/?page_size=10000 | jq -r '.last_updated')
    echo $updated_time
    datetime=$updated_time
    timeago='50 days ago'

    dtSec=$(date --date "$datetime" +'%s')
    taSec=$(date --date "$timeago" +'%s')

    echo "INFO: dtSec=$dtSec, taSec=$taSec" 

           if [ $dtSec -lt $taSec ] 
           then
              echo "This image ${ORG}/${i}:${j} is older than 50 days, deleting this  image"
              ## Please uncomment below line to delete docker hub images of docker hub repositories
              curl -s  -X DELETE  -H "Authorization: JWT ${TOKEN}" https://hub.docker.com/v2/repositories/${ORG}/${i}/tags/${j}/
           else
              echo "This image ${ORG}/${i}:${j} is within 50 days time range, keep this image"
           fi      
  done
done

echo "Script execution ends"

