# Use Base image with Espressif IDF (Version 4.4.1)
FROM espressif/idf:v4.4.1

LABEL image.name="euphonium_builder_4mb"

# Set workdir
WORKDIR /app

# install stuff
RUN apt-get update && apt-get upgrade -y && apt-get install -y git protobuf-compiler python3-protobuf

# install Node.js, NPM
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
RUN apt-get install -y nodejs

# Euphonium Repository klonen
RUN git clone --recursive --branch louderESP https://github.com/LeoSum8/euphonium_louderESP.git .

# install requirements
RUN pip install -r requirements.txt
RUN pip install protobuf==3.20.1

# Configure Yarn
RUN corepack enable
RUN yarn set version stable
RUN rm -rf bu

# Optionally set wifi settings during build
# RUN mkdir /app/euphonium/scripts/configuration/
# RUN echo '{"ssid": "SSID", "password": "PASSWORD"}' > /app/euphonium/scripts/configuration/wifi.config.json

# Build- and Copy script
RUN echo '#!/bin/bash\n\
git pull\n\
cd /app/targets/esp32\n\
sh build_recovery.sh\n\
pip install protobuf==3.20.1\n\
sh build_app.sh\n\
cp -r build /app/build\n' > /app/build_and_copy.sh && \
chmod +x /app/build_and_copy.sh

# exec build and copy script on startup
CMD ["/app/build_and_copy.sh"]
