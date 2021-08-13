# htmltopdf
Маленький сервис по конвертации html в pdf.

# Описание
Этот сервис представляет из себя unix демон, который предоставляет API
через методы протокола HTTP/1.1. Демон использует модель fork для обработки запросов.
Для конвертации html в pdf используется [wkhtmltopdf](https://wkhtmltopdf.org).

# Документация
Подробная документация по API предоставлена [тут](doc/api_htmltopdf.html)
в формате [TiddlyWiki](https://ru.wikipedia.org/wiki/TiddlyWiki).

# Установка
> Установка описана для Centos7.
> В других дистрибутивах не должно возникнуть проблем, просто нужно заменить названия пакетов.


> На сервере последовательно выполняем действия в командной строке
> от пользователя root если не сказано иное.

подключение репозитория epel
```sh
yum -y install epel-release
```

установка зависисмостей
```sh
yum -y install perl wget liberation-serif-fonts ghostscript
yum -y install perl-parent perl-Net-Server perl-Plack \
  perl-Pod-Usage perl-Log-Dispatch perl-Archive-Zip perl-File-Temp perl-Capture-Tiny \
  perl-Image-ExifTool perl-Config-Tiny
```

установка пакета wkhtmltopdf с оффициального сайта
```sh
yum -y install https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox-0.12.6-1.centos7.x86_64.rpm
```

создание пользователя, от которого будет работать демон API
```sh
useradd -r -c "api conversion html to pdf" -d /opt/htmltopdf -s /bin/bash htmltopdf
```

получение исходников демона (ориентируйтесь на текущий релиз)
```sh
wget -O /tmp/htmltopdf_3.0.0.tar.gz https://github.com/krpsh123/htmltopdf/archive/refs/tags/3.0.0.tar.gz
```

распаковка исходников
```sh
tar -xvzf /tmp/htmltopdf_3.0.0.tar.gz -C /opt
```

создание файла для хранения токенов авторизации на нашем API /opt/htmltopdf/api/acl.conf
```
# каждый токен на отдельной строке
# например:
# bea606df1a111f5eed3d2b88eba30bcb
# 56fe5d5ee5abaf9934227091a6b32ab5
# ...
#
# токен можно получать командой:
# echo -n `date '+%a, %d %b %Y %T %z %N'` | md5sum | awk '{print $1}'
#

# Воркутинский филиал "Рога и копыта"
a02655d46dd0f2160529acaccd4dbf9
```

установка владельца файлов
```sh
chown -R htmltopdf.htmltopdf /opt/htmltopdf
```

включение ротации логов
```sh
cat /opt/htmltopdf/htmltopdf.logrotate > /etc/logrotate.d/htmltopdf
```

```sh
включение автозапуска и запуск демона
cat /opt/htmltopdf/htmltopdf.service > /etc/systemd/system/htmltopdf.service
systemctl enable htmltopdf && systemctl start htmltopdf
```

