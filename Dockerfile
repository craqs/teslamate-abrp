ARG BUILD_FROM
FROM $BUILD_FROM

WORKDIR /app

RUN apk add python3 py3-pip

COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

COPY teslamate_mqtt2abrp.py .

COPY rootfs /
