FROM alpine:3.10.1

ENV CIMI_HOST=cimi \
    CIMI_PORT=80

WORKDIR /app/
CMD /app/bootstrap.sh
RUN apk add curl jq gettext

COPY bootstrap.sh /app/
COPY resources/ /app/resources/
