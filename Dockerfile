FROM alpine:3.20

# bash is required by the scripts' shebang; Alpine's busybox ping/df/etc.
# already cover everything else the scripts need.
RUN apk add --no-cache bash

WORKDIR /app

COPY app/ /app/

RUN chmod +x /app/diagnostic.sh /app/health-check.sh

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD ["/app/health-check.sh"]

ENTRYPOINT ["/app/diagnostic.sh"]
CMD ["help"]
