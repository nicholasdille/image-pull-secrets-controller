FROM alpine@sha256:c5b1261d6d3e43071626931fc004f70149baeba2c8ec672bd4f27761f8e1ad6b

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
