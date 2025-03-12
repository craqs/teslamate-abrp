[![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fcraqs%2Fteslamate-abrp)

# TeslaMate: MQTT to ABRP
[![amd64+arm64 :alpha build](https://github.com/fetzu/teslamate-abrp/actions/workflows/build_alpha.yml/badge.svg)](https://github.com/fetzu/teslamate-abrp/actions/workflows/build_alpha.yml)
[![amd64+arm64 :beta build](https://github.com/fetzu/teslamate-abrp/actions/workflows/build_beta.yml/badge.svg)](https://github.com/fetzu/teslamate-abrp/actions/workflows/build_beta.yml)
[![amd64+arm64 :latest build](https://github.com/fetzu/teslamate-abrp/actions/workflows/build_latest.yml/badge.svg)](https://github.com/fetzu/teslamate-abrp/actions/workflows/build_latest.yml)
[![](https://img.shields.io/github/v/release/fetzu/teslamate-abrp)](https://github.com/fetzu/teslamate-abrp/releases/latest)
[![](https://img.shields.io/docker/image-size/fetzu/teslamate-abrp/latest)](https://hub.docker.com/r/fetzu/teslamate-abrp)
[![](https://img.shields.io/docker/pulls/fetzu/teslamate-abrp?color=%23099cec)](https://hub.docker.com/r/fetzu/teslamate-abrp)
[![GitHub license](https://img.shields.io/github/license/fetzu/teslamate-abrp)](https://github.com/fetzu/teslamate-abrp/blob/main/LICENSE)

A slightly convoluted way of getting your vehicle data from [TeslaMate](https://github.com/teslamate-org/teslamate) to [ABRP](https://abetterrouteplanner.com/).


## Setup and Usage
### 1. Use as Docker container
#### 1.1 Requirements
For this to work, you need a working instance of TeslaMate with MQTT enabled. See the [official TeslaMate doc](https://docs.teslamate.org/docs/installation/docker) as a reference on how this might look like.

#### 1.2 Getting a USER TOKEN from ABRP
Inside the ABRP (web)app, navigate to your car settings and use the "generic" card (last one at the very bottom) to generate your user token. Make a note of that token and keep it to yourself.

#### 1.3 Adding the service to docker-compose.yml
In your TeslaMate docker-compose.yml, add the teslamate-abrp service by adding the following lines in the "services:" section:
```yaml
ABRP:
  container_name: TeslaMate_ABRP
  image: fetzu/teslamate-abrp:latest #NOTE: you can replace ":latest" with either ":beta" (pre-release version) or ":alpha" for the bleeding edge version (note: bleeding edge might be very unstable or even not work at all)
  restart: always
  # privileged: true
  # NOTE: un-comment the previous line to run the container in privilege mode (necessary on RaspberryPi)
  environment:
    - MQTT_SERVER=mosquitto
    - USER_TOKEN=y0ur-4p1-k3y
    - CAR_NUMBER=1
    - CAR_MODEL=s100d #NOTE: This is optional, see below
```

Make sure to adapt the following environment variables:

- The first value MQTT_SERVER corresponds to the name of your MQTT service name ("mosquitto" in the doc).
- The second values (USER_TOKEN) correspond to the value provided by ABRP.
- The third value corresponds to your car number (1 if you only have a single car).
- The last value corresponds to your car model. When this value is not set, the script will try to determine your car model automatically (this should work for Models S, X, 3 and Y with standard configs). __The detection is very bare-bones and will not take into account factors such as wheel type, heat pump, LFP battery. It is recommended you take a moment to find your car model on https://api.iternio.com/1/tlm/get_carmodels_list and use the corresponding key as a value for CAR_MODEL (e.g. "tesla:m3:20:bt37:heatpump" for a 2021 Model 3 LR).__
- Additionally;
  - MQTT_PASSWORD and/or MQTT_USERNAME: can be set to use authentication on the MQTT server.
  - MQTT_TLS: will connect to the MQTT server with encryption, the server must have certificates configured.
  - MQTT_PORT: is the port the MQTT server is listening on, defaults to 1883 and if you are using TLS this probably should be set to 8883
  - STATUS_TOPIC: can be set to a MQTT topic where status messages will be sent, write permissions will be needed for this specific topic.
  - SKIP_LOCATION: If you don't want to share your location with ABPR (Iternio), give this environment variable a value and the lat and lon values will always be 0
  - TM2ABRP_DEBUG: set (to any value) sets logging level to DEBUG and give you a more verbose logging.


Then from the command line, navigate to the folder where your docker-compose.yml is located and run:
```
docker-compose pull ABRP
docker-compose up -d ABRP
```

If all goes well, your car should be shown as online in ABRP after a minute. Logging should show "YYYY-MM-DD HH:MM:SS: [INFO] Connected with result code 0. Connection with MQTT server established.".

#### 1.4 Security

If you want to follow dockers recommendations regarding secrets, you should not provide them as `ENVIRONMENT VARIABLE` or command line parameters and instead use the build in [secrets function](https://docs.docker.com/compose/use-secrets/). This will expose the secrets in the container to the file system at `/run/secrets/`. Read the documentation carefully if you wish to use docker's secrets feature.

This is an example of a part of a docker-compose.yml file using:

- Secrets instead of environment variables
- TLS enabled on the MQTT Server
- A status topic provided
- Flag set not to send latitude and longitude information to ABRP
- Debug level logging activated

```yaml
version: '3'
services:
  # [...Other services such as TeslaMate, postgres, Grafana and the MQTT broker go here...]
  MQTT2ABRP:
    container_name: TeslaMate_ABRP
    image: fetzu/teslamate-abrp:latest #NOTE: you can replace ":latest" with ":beta" to use the bleeding edge version, without any guarantees.
    restart: always
    environment:
      CAR_NUMBER: 1
      MQTT_SERVER: your.server.tld # Replace with your server's service name or IP address
      MQTT_PORT: 8883 # This is a TLS enabled server, and usually that is enabled on a different port than the default 1883
      MQTT_USERNAME: myMQTTusername # Replace with your actually mqtt username
      MQTT_TLS: True # Connect to the MQTT server encrypted
      STATUS_TOPIC: teslamate-abrp # This will send status messages and a copy of the ABRP data to the topic "teslamate-abrp/xxx"
      TM2ABRP_DEBUG: True # This will enable debug level logging
      SKIP_LOCATION: True # Don't send location info to ABRP
      TZ: "Europe/Stockholm"
    secrets:
      - USER_TOKEN # Instead of having your token in clear text, it's found in the file below
      - MQTT_PASSWORD # Instead of having your password in clear text, it's found in the file below

secrets:
# These text files contains the token/passwords, and nothing else.
# They can be placed "anywhere" on the host system and protected by appropriate file permissions.
  USER_TOKEN:
    file: ./path/to/abrp-token.txt
  MQTT_PASSWORD:
    file: ./path/to/abrp-mqtt-pass.txt
```

To run it:
```bash
docker compose up -d
```

### 2. Use as python script
The script can also be run directly on a machine with Python 3.x. Please note that the machine needs to have access to your MQTT server on port 1883.

#### 2.1 Installing requirements
To install the requirements, run
```
pip install -r requirements.txt
```

#### 2.2 Running

To run, you can either use the CLI. Please note that USER_TOKEN, CAR_NUMBER, CAR_MODEL and MQTT_SERVER are required arguments.

If you are using a MQTT server with username or authentication, pass the -l (to use MQTT_USERNAME only) or -p (for authentication with MQTT_USERNAME and MQTT_PASSWORD) options. [Be aware that passing a username and password on an MQTT server not set for it will cause the connection to fail](https://github.com/fetzu/teslamate-abrp/issues/25).


```
Usage:
    teslamate_mqtt2abrp.py [-hdlpsx] [USER_TOKEN] [CAR_NUMBER] [MQTT_SERVER] [MQTT_USERNAME] [MQTT_PASSWORD] [MQTT_PORT] [--model CAR_MODEL] [--status_topic TOPIC]

Arguments:
    USER_TOKEN            User token generated by ABRP.
    CAR_NUMBER            Car number from TeslaMate (usually 1).
    MQTT_SERVER           MQTT server address (e.g. "192.168.1.1").
    MQTT_PORT             MQTT port (e.g. 1883 or 8883 for TLS).
    MQTT_USERNAME         MQTT username, use with -l or -p.
    MQTT_PASSWORD         MQTT password, use with -p.

Options:
    -h                    Show this screen.
    -d                    Debug mode (set logging level to DEBUG)
    -l                    Use username to connect to MQTT server.
    -p                    Use authentication (user and password) to connect to MQTT server.
    -s                    Use TLS to connect to MQTT server, environment variable: MQTT_TLS
    -x                    Don't send LAT and LON to ABRP, environment variable: SKIP_LOCATION
    --model CAR_MODEL     Car model according to https://api.iternio.com/1/tlm/get_CARMODELs_list
    --status_topic TOPIC  MQTT topic to publish status messages to, if not set, no publish will be done.

Note:
    All arguments can also be passed as corresponding OS environment variables.
```
**Note: All arguments can also be passed as corresponding OS environment variables.** Arguments passed through the CLI will always supersede OS environment variables and docker secrets (in that order).


## Credits

Based on/forked from [letienne's original code](https://github.com/letienne/teslamate-abrp), with improvement by various contributors (see [commit history](https://github.com/fetzu/teslamate-abrp/commits/main)).


## License

Licensed under the [MIT license](https://github.com/fetzu/teslamate-abrp/blob/main/LICENSE).
