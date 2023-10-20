FROM alpine@sha256:eece025e432126ce23f223450a0326fbebde39cdf496a85d8c016293fc851978

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
