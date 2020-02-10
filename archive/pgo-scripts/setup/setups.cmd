
rem create databases and users
type setups.sql | mysql -u root

rem setup 
mysql -u root wordpress < wordpress\wordpress.sql
%windir%\system32\inetsrv\appcmd add apppool /in < wordpress\apppool.xml
%windir%\system32\inetsrv\appcmd add site /in < wordpress\site.xml