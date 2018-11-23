sed -i '/<VirtualHost _default_:443>/a ProxyPass \/ https:\/\/127.0.0.1:8000\/' /etc/httpd/conf.d/ssl.conf
sed -i '/<VirtualHost _default_:443>/a ProxyPassReverse \/ https:\/\/127.0.0.1:8000\/' /etc/httpd/conf.d/ssl.conf
sed -i '/<VirtualHost _default_:443>/a SSLProxyEngine on' /etc/httpd/conf.d/ssl.conf
sed -i '/<VirtualHost _default_:443>/a SSLProxyVerify none' /etc/httpd/conf.d/ssl.conf
printf "\nenableSplunkWebSSL = true" >> /opt/splunk/etc/system/local/web.conf
sudo service splunk restart
sudo service httpd restart

