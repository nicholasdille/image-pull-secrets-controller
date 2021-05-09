FROM alpine@sha256:69e70a79f2d41ab5d637de98c1e0b055206ba40a8145e7bddb55ccc04e13cf8f

RUN echo "@testing http://nl.alpinelinux.org/alpine/edge/testing" >>/etc/apk/repositories \
 && echo "@edgecommunity http://nl.alpinelinux.org/alpine/edge/community" >>/etc/apk/repositories \
 && apk add --update-cache --no-cache \
        bash \
        curl \
        jq \
        kubectl@testing \
        yq@edgecommunity

COPY . /opt/image-pull-secrets-controller/
WORKDIR /opt/image-pull-secrets-controller
ENTRYPOINT [ "bash", "image-pull-secrets-controller.sh" ]