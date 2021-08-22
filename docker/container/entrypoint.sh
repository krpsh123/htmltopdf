#!/bin/bash

if [ "$1" = 'htmltopdf' ]; then
	chown -R htmltopdf.htmltopdf /opt/htmltopdf
	chmod +x /opt/htmltopdf/api/htmltopdfd
	exec /opt/htmltopdf/api/htmltopdfd -p $HTMLTOPDF_PORT -u htmltopdf -E production /opt/htmltopdf/api/app.psgi
fi

exec $@
