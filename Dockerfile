FROM alpine@sha256:4edbd2beb5f78b1014028f4fbb99f3237d9561100b6881aabbf5acce2c4f9454

RUN echo "@testing http://nl.alpinelinux.org/alpine/edge/testing" >>/etc/apk/repositories \
 && echo "@edgecommunity http://nl.alpinelinux.org/alpine/edge/community" >>/etc/apk/repositories \
 && apk add --update-cache --no-cache \
        bash \
        curl \
        jq \
        kubectl@edgecommunity \
        yq

COPY . /opt/image-pull-secrets-controller/
WORKDIR /opt/image-pull-secrets-controller
ENTRYPOINT [ "bash", "image-pull-secrets-controller.sh" ]
