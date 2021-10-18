FROM alpine@sha256:e1c082e3d3c45cccac829840a25941e679c25d438cc8412c2fa221cf1a824e6a

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