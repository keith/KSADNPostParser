#!/usr/bin/env bash

git submodule update --init --recursive
cd Example/Vendor/Specta; rake
cd ../Expecta; rake
cd ../../../

