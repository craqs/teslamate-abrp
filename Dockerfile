ARG BUILD_FROM
FROM $BUILD_FROM

WORKDIR /app

RUN apk add python

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY teslamate_mqtt2abrp.py .

COPY rootfs /
