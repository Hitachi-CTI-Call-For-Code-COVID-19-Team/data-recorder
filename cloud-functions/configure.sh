#!/bin/bash -eu

ICFN_NAMESPACE="data-recorder"
icfn="ibmcloud fn"
CLOUDANT_SERVICE_INSTANCE="cloudant-dev"
CLOUDANT_DB="z_iotp_o9ypqz_default"
CLOUDANT_SERVICE_CREDENTIAL="ServiceCredential_Writer"
ICFN_CLOUDANT_PACKAGE="event-streams_cloudant"
ICFN_PACKAGE="event-streams"
ICFN_SEQUENCE="seq01"
ICFN_ES_EVENT_RECEIVED="message-received-trigger"
ICFN_ES_PACKAGE="event-streams"
ES_SERVICE_INSTANCE="Event Streams"
ES_SERVICE_CREDENTIAL="cloudant"
ES_TOPIC="covsafe"
ES_USER="token"
ES_PASSWORD="<PLEASE_MODIFY_HERE>"
ES_ADMIN_URL="https://k8kj3frcq282j5n7.svc01.jp-tok.eventstreams.cloud.ibm.com"



$icfn property set --namespace $ICFN_NAMESPACE

##--------------------------------------------------------------
## Preparation: Setup binding b/w Cloud Functions and Cloudant.
##--------------------------------------------------------------
# Create the cloudant package binding.
$icfn package bind /whisk.system/cloudant $ICFN_CLOUDANT_PACKAGE --param dbname $CLOUDANT_DB
# Bind the cloudant service to the package.
$icfn service bind cloudantnosqldb $ICFN_CLOUDANT_PACKAGE \
        --instance $CLOUDANT_SERVICE_INSTANCE \
            --keyname $CLOUDANT_SERVICE_CREDENTIAL

## --------------------------------------------------------------
## Create Cloud IBM Functions Sequence and Actions
## --------------------------------------------------------------
$icfn package create $ICFN_PACKAGE
$icfn action create "$ICFN_PACKAGE/process-message" "process-message.js" --kind nodejs:10
$icfn action create "$ICFN_PACKAGE/$ICFN_SEQUENCE" \
        --sequence "$ICFN_PACKAGE/process-message","$ICFN_CLOUDANT_PACKAGE/manage-bulk-documents"


##--------------------------------------------------------------
## Preparation: Setup binding b/w Cloud Functions and EventStreams.
##--------------------------------------------------------------
$icfn package bind /whisk.system/messaging $ICFN_ES_PACKAGE \
    -p kafka_brokers_sasl \
    "[\"broker-2-k8kj3frcq282j5n7.kafka.svc01.jp-tok.eventstreams.cloud.ibm.com:9093\", \"broker-4-k8kj3frcq282j5n7.kafka.svc01.jp-tok.eventstreams.cloud.ibm.com:9093\", \"broker-0-k8kj3frcq282j5n7.kafka.svc01.jp-tok.eventstreams.cloud.ibm.com:9093\", \"broker-1-k8kj3frcq282j5n7.kafka.svc01.jp-tok.eventstreams.cloud.ibm.com:9093\", \"broker-3-k8kj3frcq282j5n7.kafka.svc01.jp-tok.eventstreams.cloud.ibm.com:9093\", \"broker-5-k8kj3frcq282j5n7.kafka.svc01.jp-tok.eventstreams.cloud.ibm.com:9093\"]" \
    -p user $ES_USER -p password $ES_PASSWORD -p kafka_admin_url $ES_ADMIN_URL
$icfn service bind messagehub $ICFN_ES_PACKAGE \
    --instance $ES_SERVICE_INSTANCE \
    --keyname $ES_SERVICE_CREDENTIAL
## ---------------------------------------------------------------
## Create Trigger and Rules
## ---------------------------------------------------------------
$icfn trigger create $ICFN_ES_EVENT_RECEIVED -f $ICFN_ES_PACKAGE/messageHubFeed  -p $ES_TOPIC -p isJSONData true
$icfn rule create $ICFN_PACKAGE"_"$ICFN_SEQUENCE"_"$ICFN_ES_EVENT_RECEIVED $ICFN_ES_EVENT_RECEIVED $ICFN_SEQUENCE
