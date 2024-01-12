#!/usr/bin/env bash

git remote add target https://${INPUT_TARGET_USERNAME}:${INPUT_TARGET_TOKEN}@${INPUT_TARGET_URL#https://}

if [[ ${INPUT_TARGET_FORCE_PUSH} == "true" ]]; then
  git push target --all -f
else
  git push target --all
fi