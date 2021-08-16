#!/bin/bash

ZIP=/tmp/probapera.zip

rm -f $ZIP
7z a -tzip $ZIP ./template/*

curl -v -X POST -H 'Authorization: Bearer a02655d46dd0f2160529acaccd4dbf9' --data-binary "@$ZIP" 127.0.0.1:50002/htmltopdf > /tmp/probapera.pdf