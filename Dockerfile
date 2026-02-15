# --- Stage 1: Downloader ---
FROM alpine:latest AS fetcher
WORKDIR /setup
ENV MC_VERSION=1.21.1
ENV FABRIC_LOADER=0.18.4
ENV FABRIC_INSTALLER=1.1.1

RUN apk add --no-cache curl
RUN curl -o fabric-server.jar https://meta.fabricmc.net/v2/versions/loader/${MC_VERSION}/${FABRIC_LOADER}/${FABRIC_INSTALLER}/server/jar

# --- Stage 2: Final Runtime ---
FROM eclipse-temurin:21-jre-jammy

# Setup user and directories
RUN useradd -m minecraft
WORKDIR /data

# 1. Copy the jar to a BACKUP location outside the /data volume
COPY --from=fetcher /setup/fabric-server.jar /fabric-server.jar.bak

# 2. Setup the entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 3. Pre-accept EULA (this will be copied to SSD by entrypoint if missing)
RUN echo "eula=true" > /eula.txt.bak

# Switch to root temporarily so the entrypoint can fix permissions on startup
USER root
ENTRYPOINT ["/entrypoint.sh"]

# Optimized One-Liner CMD
CMD ["java", "-Xms6G", "-Xmx6G", "-XX:+UseG1GC", "-XX:+ParallelRefProcEnabled", "-XX:MaxGCPauseMillis=100", "-XX:+UnlockExperimentalVMOptions", "-XX:+DisableExplicitGC", "-XX:+AlwaysPreTouch", "-XX:G1NewSizePercent=30", "-XX:G1MaxNewSizePercent=40", "-XX:G1HeapRegionSize=8M", "-XX:G1ReservePercent=20", "-XX:G1HeapWastePercent=5", "-XX:G1MixedGCCountTarget=4", "-XX:InitiatingHeapOccupancyPercent=15", "-XX:G1MixedGCLiveThresholdPercent=90", "-XX:G1RSetUpdatingPauseTimePercent=5", "-XX:SurvivorRatio=32", "-XX:+PerfDisableSharedMem", "-XX:MaxTenuringThreshold=1", "-XX:ParallelGCThreads=4", "-jar", "fabric-server.jar", "nogui"]
