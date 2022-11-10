FROM openresty/openresty:bullseye-fat
WORKDIR /etc/nginx
COPY nginx-default.conf conf.d/default.conf
COPY certs/server.key\
 certs/server.crt\
 certs/server-ca.crt\
 ssl/
