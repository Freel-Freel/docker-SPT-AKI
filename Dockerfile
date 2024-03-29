FROM node:20.11.1-bookworm AS builder

ENV AKI_SERVER_MOD="1.6.2"
ENV SPT_AKI="3.8.0"

RUN sh -c 'echo "Acquire::http {No-Cache=True;};" >> /etc/apt/apt.conf'
RUN apt update
RUN apt install ca-certificates tzdata git git-lfs -y

WORKDIR /app

RUN git clone https://dev.sp-tarkov.com/SPT-AKI/Server.git && \
    cd Server && git checkout $SPT_AKI
 
RUN cd /app/Server/project/ && yarn
RUN cd /app/Server/project/ && yarn run build:release

RUN git clone https://github.com/stayintarkov/SIT.Aki-Server-Mod.git && \
    cd SIT.Aki-Server-Mod && git checkout $AKI_SERVER_MOD 

##############################################

FROM debian:bookworm

ENV TZ="Europe/Moscow"
ENV TARRKOV_PVE_DIR "/var/lib"
ENV buildTag=0.0.3


RUN sh -c 'echo "Acquire::http {No-Cache=True;};" >> /etc/apt/apt.conf'
RUN apt update && \
    apt install ca-certificates tzdata -y && \
    rm -rf /var/cache/apt/*

RUN echo ${TZ} > /etc/timezone && \
    cp /usr/share/zoneinfo/${TZ} /etc/localtime


ARG USER=tarkov
ARG UID=1000
ARG GID=1000

RUN adduser --uid ${UID} --shell /bin/sh --home ${TARRKOV_PVE_DIR}/${USER} --disabled-password ${USER}

COPY --chown=${USER}  --from=builder /app/Server/project/build ${TARRKOV_PVE_DIR}/${USER}
COPY --chown=${USER}  --from=builder /app/SIT.Aki-Server-Mod ${TARRKOV_PVE_DIR}/${USER}/user/mods/SITCoop

RUN mkdir -p ${TARRKOV_PVE_DIR}/${USER}/user/logs && \
    mkdir -p ${TARRKOV_PVE_DIR}/${USER}/user/profiles && \
    mkdir -p ${TARRKOV_PVE_DIR}/${USER}/user/cache && \
    chown -R ${USER}:${USER} ${TARRKOV_PVE_DIR}/${USER}/user

COPY --chown=${USER} Server/configs/http.json ${TARRKOV_PVE_DIR}/${USER}/Aki_Data/Server/configs
COPY --chown=${USER} Server/database/server.json ${TARRKOV_PVE_DIR}/${USER}/Aki_Data/Server/database
COPY --chown=${USER} mods/SITCoop/config/*.json ${TARRKOV_PVE_DIR}/${USER}/user/mods/SITCoop/config/

USER $USER
WORKDIR ${TARRKOV_PVE_DIR}/${USER}

EXPOSE 6969,6970,6971

CMD ["/var/lib/tarkov/Aki.Server.exe"]
