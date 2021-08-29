# Base + R + tidyverse original image: https://hub.docker.com/u/oliverstatworx/
FROM jmartinez19/base-r-tidyverse-sf:latest

# Dir
RUN mkdir -p /data

# Copy script
COPY ./process-nmea.R /

# Entrypoint
ENTRYPOINT ["/process-nmea.R", "-p", "/data"]
