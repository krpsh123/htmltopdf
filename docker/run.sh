#!/bin/sh

docker run \
  --name htmltopdf \
  --net host \
  --detach \
  --volume /etc/localtime:/etc/localtime:ro \
  --volume /opt/htmltopdf_docker/log:/opt/htmltopdf/api/log \
  --volume /opt/htmltopdf_docker/unzipping:/opt/htmltopdf/api/unzipping \
  --volume /opt/htmltopdf_docker/acl.conf:/opt/htmltopdf/api/acl.conf \
  htmltopdf:3.2.0

#  --restart unless-stopped \
#  --env HTMLTOPDF_PORT=50003 \
