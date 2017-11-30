FROM deliveroo/hopper-runner:1.0.0 as hopper-runner
FROM golang:1.9.2-alpine
MAINTAINER team@pganalyze.com

RUN adduser -D pganalyze pganalyze
ENV GOPATH /go
ENV HOME_DIR /home/pganalyze
ENV CODE_DIR $GOPATH/src/github.com/pganalyze/collector


COPY --from=hopper-runner /hopper-runner /usr/bin/hopper-runner

COPY . $CODE_DIR
WORKDIR $CODE_DIR

# We run this all in one layer to reduce the resulting image size
RUN apk add --no-cache --virtual .build-deps make curl libc-dev gcc go git tar \
  && apk add --no-cache ca-certificates \
  && make build_dist OUTFILE=$HOME_DIR/collector \
  && rm -rf $GOPATH \
  && apk del --purge .build-deps

RUN mkdir /state
RUN chown pganalyze:pganalyze /state
VOLUME ["/state"]

ENTRYPOINT ["hopper-runner"]
USER pganalyze
CMD ["/home/pganalyze/collector", "--verbose", "--statefile=/state/pganalyze-collector.state"]
