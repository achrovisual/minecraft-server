#!/bin/bash
set -e

# Copy JAR if missing
if [ ! -f "/data/fabric-server.jar" ]; then
    cp /fabric-server.jar.bak /data/fabric-server.jar
fi

# Copy EULA if missing
if [ ! -f "/data/eula.txt" ]; then
    echo "eula=true" > /data/eula.txt
fi

# Fix permissions
chown -R minecraft:minecraft /data

exec "$@"
