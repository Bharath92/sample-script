#!/bin/bash -e

export API_PARAMS="api_params"

export API_PARAMS_UP=$(echo $API_PARAMS | awk '{print toupper($0)}')
export API_PARAMS_STR=$API_PARAMS_UP"_PARAMS"

__initialize() {
  API_RESPONSE_FILE="apiResponseBody"
  API_URL=$(eval echo "$"$API_PARAMS_STR"_APIURL")
  API_TOKEN=$(eval echo "$"$API_PARAMS_STR"_APITOKEN")
  QUEUE_LIMIT=$(eval echo "$"$API_PARAMS_STR"_QUEUE_LIMIT")
  QUEUE_LIMIT_JOBTRIGGER=$(eval echo "$"$API_PARAMS_STR"_QUEUE_LIMIT_JOBTRIGGER")
  RESPONSE_CODE=404
  RESPONSE_DATA=""
  CURL_EXIT_CODE=0

  touch $API_RESPONSE_FILE
}

__display_queue_messages() {
  local message="Queue: $1 Count: $2"
  echo "|___ $message"
}

__shippable_get() {
  __initialize

  local url="$API_URL/$1"
  {
    RESPONSE_CODE=$(curl \
      -H "Content-Type: application/json" \
      -H "Authorization: $API_TOKEN" \
      -X GET $url \
      --silent --write-out "%{http_code}\n" \
      --output $API_RESPONSE_FILE)
  } || {
    CURL_EXIT_CODE=$(echo $?)
  }

  if [ $CURL_EXIT_CODE -gt 0 ]; then
    # we are assuming that if curl cmd failed, API is unavailable
    response="curl failed with error code $CURL_EXIT_CODE. API might be down."
    RESPONSE_CODE=503
  else
    RESPONSE_CODE="$RESPONSE_CODE"
    RESPONSE_DATA=$(cat $API_RESPONSE_FILE)
  fi

  rm -f $API_RESPONSE_FILE

  if [ "$RESPONSE_CODE" -gt 299 ]; then
    echo "Error GET-ting queues: $RESPONSE_DATA"
    echo "Response status code: $RESPONSE_CODE"
    exit 1
  fi
}

shippable_get_queues() {
  shouldAlert=false
  local platform_queues_get_endpoint="platform/queues"
  __shippable_get $platform_queues_get_endpoint
  queues=$(echo $RESPONSE_DATA | jq '[ .[] | select(.messages >= '$QUEUE_LIMIT') ]')
  queues_length=$(echo $queues | jq '. | length')
  if [ $queues_length -eq 0 ]; then
    exit 0
  fi
  for i in $(seq 1 $queues_length); do
    local queue=$(echo $queues | jq '.['"$i-1"']')
    local queue_name=$(echo $queue | jq '.name')
    local queue_messages=$(echo $queue | jq '.messages')
    if [[ $queue_name != *".quarantine"* ]]; then
      if [[ "$queue_name" = "job.trigger" ]]; then
        if [ $queue_messages -gt $QUEUE_LIMIT_JOBTRIGGER ]; then
          shouldAlert=true
          __display_queue_messages $queue_name $queue_messages
        fi
      else
        __display_queue_messages $queue_name $queue_messages
        shouldAlert=true
      fi
    fi
  done
  if [ "$shouldAlert" = true ]; then
    exit 1
  fi
}

main() {
  shippable_get_queues
}

main
