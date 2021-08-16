# htmltopdf
Small service for converting html to pdf.

# Description
This service is a unix daemon that provides an API through the methods of the HTTP/1.1 protocol.
The daemon uses the fork model to process requests. To convert html to pdf, wkhtmltopdf is used.

# Documentation
Detailed API documentation is provided [here](doc/api_htmltopdf.html)
in the TiddlyWiki format.

# Install
> The installation is described for Centos 7.
> There should be no problems in other distributions, you just need to replace the package names.

> On the server, actions are performed sequentially on the command line from the root user, unless otherwise specified.

adding an epel repository
```sh
yum -y install epel-release
```

installing dependencies
```sh
yum -y install perl wget liberation-serif-fonts ghostscript
yum -y install perl-parent perl-Net-Server perl-Plack \
  perl-Pod-Usage perl-Log-Dispatch perl-Archive-Zip perl-File-Temp perl-Capture-Tiny \
  perl-Image-ExifTool perl-Config-Tiny
```

installing the wkhtmltopdf package from the official website
```sh
yum -y install https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox-0.12.6-1.centos7.x86_64.rpm
```

creating a user from whom the API daemon will work
```sh
useradd -r -c "api conversion html to pdf" -d /opt/htmltopdf -s /bin/bash htmltopdf
```

getting the source code of the daemon (focus on the current release)
```sh
wget -O /tmp/htmltopdf_3.0.0.tar.gz https://github.com/krpsh123/htmltopdf/archive/refs/tags/3.0.0.tar.gz
```

unpacking the source code
```sh
tar -xvzf /tmp/htmltopdf_3.0.0.tar.gz -C /opt
```

creating a file for storing authorization tokens on our API: /opt/htmltopdf/api/acl.conf
```
# each token on a separate line
# example:
# bea606df1a111f5eed3d2b88eba30bcb
# 56fe5d5ee5abaf9934227091a6b32ab5
# ...
#
# the token can be obtained by the command:
# echo -n `date '+%a, %d %b %Y %T %z %N'` | md5sum | awk '{print $1}'
#

# Horns and Hooves branch
a02655d46dd0f2160529acaccd4dbf9
```

setting the file owner
```sh
chown -R htmltopdf.htmltopdf /opt/htmltopdf
```

enabling log rotation
```sh
cat /opt/htmltopdf/htmltopdf.logrotate > /etc/logrotate.d/htmltopdf
```

enabling auto start and launching the daemon
```sh
cat /opt/htmltopdf/htmltopdf.service > /etc/systemd/system/htmltopdf.service
systemctl enable htmltopdf && systemctl start htmltopdf
```

