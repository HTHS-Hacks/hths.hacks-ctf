FROM ubuntu:18.04

EXPOSE 22
EXPOSE 80
EXPOSE 443
EXPOSE 1025-65525

ADD setup.sh /

RUN chmod +x /setup.sh
ENTRYPOINT ["/setup.sh"]
