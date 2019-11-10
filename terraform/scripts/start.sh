#! /usr/bin/env bash

pkill swift
cd .build/release
./S3_ARServer_Kitura
cd -
