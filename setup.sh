#!/usr/bin/env bash

git submodule update --init --recursive
echo "Setting up test frameworks..."
cd Example/Vendor/Specta; rake > /dev/null
cd ../Expecta; rake > /dev/null
echo "Done"
cd ../../../

