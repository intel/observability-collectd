#!/bin/bash

while read -r key value
do
  echo "$key" "$value" >> /tmp/notifications
done
