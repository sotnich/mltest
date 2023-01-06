#!/bin/bash

cd ./infra || exit
terraform init
terraform apply
cd ..

cd featurestore/feast/repo || exit
feast apply
CURRENT_TIME=$(date -u +"%Y-%m-%dT%H:%M:%S")
feast materialize-incremental "$CURRENT_TIME"
cd ../../..
