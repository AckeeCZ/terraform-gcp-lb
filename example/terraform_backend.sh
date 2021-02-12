#!/usr/bin/env bash

export GOOGLE_PROJECT=ackee-production
export TF_VAR_region=europe-west3
export TF_VAR_zone=europe-west3-c
export TF_VAR_project=${GOOGLE_PROJECT}

terraform init
