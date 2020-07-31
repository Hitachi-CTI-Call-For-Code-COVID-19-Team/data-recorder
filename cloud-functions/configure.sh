#!/bin/bash -eu

# This is the name of namespace of data-recorder. Modify here to fit your environment.
ICFN_NAMESPACE="data-recorder"
ic="ibmcloud"
icfn="ibmcloud fn"
# This is the instance name of cloudant. Modify here to fit your environment.
CLOUDANT_SERVICE_INSTANCE="cloudant-dev" 
CLOUDANT_DB="z_iotp_o9ypqz_default"
# These are the name of writer-role credentials about cloudant. Modify here to fit your environment.
CLOUDANT_SERVICE_CREDENTIAL_WRITER="cloudant-key-writer"
ICFN_CLOUDANT_PACKAGE="event-streams_cloudant"
ICFN_PACKAGE="event-streams"
ICFN_DATA_RECORD_SEQUENCE="data-record-sequence"
ICFN_CREATE_DB__SEQUENCE="create-db-sequence"
ICFN_ES_EVENT_RECEIVED="message-received-trigger"
ICFN_FIRE_AT_MIDNIGHT_JST="fire-at-midnight-trigger"
ICFN_ES_PACKAGE="event-streams"
ES_SERVICE_INSTANCE="Event Streams"
# This is the name of reader-role credentials about event streams. Modify here to fit your environment.
ES_SERVICE_CREDENTIAL_READER="event-streams-key-reader"
ES_TOPIC="covsafe"
ES_USER="token"
##
ES_PASSWORD=$($ic resource service-key $ES_SERVICE_CREDENTIAL_READER --output JSON | jq .[]."credentials"."password")
ES_ADMIN_URL=$($ic resource service-key $ES_SERVICE_CREDENTIAL_READER --output JSON | jq .[]."credentials"."kafka_admin_url")
ES_BROKER_SASL=$($ic resource service-key event-streams-key-writer --output JSON | jq .[]."credentials"."kafka_brokers_sasl")



$icfn property set --namespace $ICFN_NAMESPACE

##--------------------------------------------------------------
## Preparation: Setup binding b/w Cloud Functions and Cloudant.
##--------------------------------------------------------------
# Create the cloudant package binding.
$icfn package bind /whisk.system/cloudant $ICFN_CLOUDANT_PACKAGE --param dbname $CLOUDANT_DB
# Bind the cloudant service to the package.
$icfn service bind cloudantnosqldb $ICFN_CLOUDANT_PACKAGE \
        --instance $CLOUDANT_SERVICE_INSTANCE \
            --keyname $CLOUDANT_SERVICE_CREDENTIAL_WRITER

## --------------------------------------------------------------
## Create Cloud IBM Functions Sequence and Actions
## --------------------------------------------------------------
$icfn package create $ICFN_PACKAGE
$icfn action create "$ICFN_PACKAGE/process-message" "process-message.js" --kind nodejs:10
$icfn action create "$ICFN_PACKAGE/$ICFN_DATA_RECORD_SEQUENCE" \
        --sequence "$ICFN_PACKAGE/process-message","$ICFN_CLOUDANT_PACKAGE/manage-bulk-documents"


##--------------------------------------------------------------
## Preparation: Setup binding b/w Cloud Functions and EventStreams.
##--------------------------------------------------------------
$icfn package bind /whisk.system/messaging $ICFN_ES_PACKAGE \
    -p kafka_brokers_sasl $ES_BROKER_SASL \
    -p user $ES_USER -p password $ES_PASSWORD -p kafka_admin_url $ES_ADMIN_URL
$icfn service bind messagehub $ICFN_ES_PACKAGE \
    --instance $ES_SERVICE_INSTANCE \
    --keyname $ES_SERVICE_CREDENTIAL_READER


## ---------------------------------------------------------------
## Create Trigger and Rules
## ---------------------------------------------------------------
$icfn trigger create $ICFN_ES_EVENT_RECEIVED -f $ICFN_ES_PACKAGE/messageHubFeed  -p $ES_TOPIC -p isJSONData true
$icfn rule create $ICFN_PACKAGE"_"$ICFN_DATA_RECORD_SEQUENCE"_"$ICFN_ES_EVENT_RECEIVED $ICFN_ES_EVENT_RECEIVED $ICFN_DATA_RECORD_SEQUENCE

## ---------------------------------------------------------------
## Create Trigger and Rules
## ---------------------------------------------------------------


$ic resource service-key cloudant-key-writer --output JSON | jq '.[]."credentials"' | jq '.|= .+{"dbname": \"z_iotp_o9ypqz_default_\" + getDateString(new Date()),}'


$icfn package create $ICFN_PACKAGE
$icfn action create "$ICFN_PACKAGE/set-params" "set-params.js" --kind nodejs:10
$icfn action create "$ICFN_PACKAGE/$ICFN_DATA_RECORD_SEQUENCE" \
        --sequence "$ICFN_PACKAGE/set-params","$ICFN_CLOUDANT_PACKAGE/create-database"

## --------------------------------------------------------------
$icfn trigger create $ICFN_FIRE_AT_MIDNIGHT_JST --feed /whisk.system/alarms/alarm -p cron "0 15 * * *"
$icfn rule create $ICFN_PACKAGE"_"$ICFN_CREATE_DB_SEQUENCE"_"$ICFN_FIRE_AT_MIDNIGHT_JST $ICFN_FIRE_AT_MIDNIGHT_JST $ICFN_CREATE_DB_SEQUENCE
