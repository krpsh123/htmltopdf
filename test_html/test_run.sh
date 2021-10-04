#!/bin/bash

ZIP=/tmp/probapera.zip

rm -f $ZIP
7z a -tzip $ZIP ./template/*

#curl -v -X POST -H 'Authorization: Bearer a02655d46dd0f2160529acaccd4dbf9' --data-binary "@$ZIP" 127.0.0.1:50002/htmltopdf > /tmp/probapera.pdf
curl -v -X POST -H 'Authorization: Bearer a02655d46dd0f2160529acaccd4dbf9' --data-binary "@$ZIP" 13.49.245.252/htmltopdf > /tmp/probapera.pdf
echo ''
echo '================================================================================================'
echo '================================================================================================'
echo '================================================================================================'
echo ''
#curl -v -X POST -H 'Authorization: Bearer a02655d46dd0f2160529acaccd4dbf9' -H 'Accept: image/jpeg' --data-binary "@$ZIP" 127.0.0.1:50002/htmltopdf > /tmp/probapera.jpg
curl -v -X POST -H 'Authorization: Bearer a02655d46dd0f2160529acaccd4dbf9' -H 'Accept: image/jpeg' --data-binary "@$ZIP" 13.49.245.252/htmltopdf > /tmp/probapera.jpg
