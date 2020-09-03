FROM ubuntu:18.04

RUN apt-get update 
RUN  apt-cache showpkg gcc
RUN apt-cache madison gcc
RUN apt-get install -y mercurial patch wget libpcre3-dev libssl-dev make gcc curl zlib1g-dev libxslt-dev

RUN set -x \
# create nginx user/group first, to be consistent throughout docker variants
    && addgroup --system --gid 1001 nginx \
    && adduser --system --disabled-login --ingroup nginx --no-create-home --home /nonexistent --gecos "nginx user" --shell /bin/false --uid 1001 nginx

WORKDIR /root
RUN hg init &&  hg clone http://hg.nginx.org/nginx/

WORKDIR /root/nginx
#checkout nginx-1.19.2-RELEASE
RUN hg update -r 7039

COPY patches/* /root/nginx/
RUN patch -p1 < ./p1 &&\
patch -p1 < ./p2 && \
patch -p1 < ./p3 && \
patch -p1 < ./p4 && \
patch -p1 < ./p5 && \
patch -p1 < ./p6 && \
patch -p1 < ./p7 && \
patch -p1 < ./p8 && \
patch -p1 < ./p9 && \
patch -p1 < ./p10 && \
patch -p1 < ./p11 && \
patch -p1 < ./p12 && \
patch -p1 < ./p13 && \
patch -p1 < ./p14

WORKDIR /root
RUN wget https://www.openssl.org/source/openssl-1.0.2h.tar.gz && tar -xvzf openssl-1.0.2h.tar.gz && rm openssl-1.0.2h.tar.gz
WORKDIR /root/nginx
RUN apt-get install -y libgd-dev libgeoip-dev libperl-dev
RUN ./auto/configure  --with-http_ssl_module  --prefix=/etc/nginx --with-openssl=/root/openssl-1.0.2h --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib64/nginx/modules --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nginx --group=nginx --with-http_ssl_module --with-http_realip_module --with-http_addition_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_stub_status_module --with-http_auth_request_module --with-http_xslt_module=dynamic --with-http_image_filter_module=dynamic --with-http_geoip_module=dynamic --with-http_perl_module=dynamic --with-threads --with-stream --with-stream_ssl_module --with-http_slice_module --with-mail --with-mail_ssl_module --with-file-aio --with-ipv6 --with-http_v2_module --with-cc-opt='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -m64 -mtune=generic'
RUN make && make install


# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log && mkdir /docker-entrypoint.d
COPY docker-entrypoint.sh /
COPY 10-listen-on-ipv6-by-default.sh /docker-entrypoint.d
COPY 20-envsubst-on-templates.sh /docker-entrypoint.d
RUN chmod +x /docker-entrypoint.sh && mkdir -p /var/cache/nginx/client_temp && mkdir /etc/nginx/conf.d/ \
&& mkdir -p /usr/share/nginx/html && cp -r /etc/nginx/html /usr/share/nginx/ 
RUN ls /usr/share/nginx/html
COPY 20-envsubst-on-templates.sh /docker-entrypoint.d
COPY nginx.conf /etc/nginx/nginx.conf
COPY conf.d/* /etc/nginx/conf.d/
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 80
EXPOSE 8081

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
