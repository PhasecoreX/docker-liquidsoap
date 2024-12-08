FROM ocaml/opam:debian-12-ocaml-4.14 AS builder

ENV PACKAGES="taglib mad lame vorbis cry samplerate opus fdkaac faad flac ocurl liquidsoap sqlite3"

USER root

RUN set -eux; \
    sed -i 's/^Components:.*/Components: main contrib non-free/g' /etc/apt/sources.list.d/debian.sources; \
    apt-get update

RUN set -eux; \
    opam depext --install $PACKAGES

RUN set -eux; \
    eval $(opam env); \
    mkdir -p /home/opam/root/app; \
    mv $(command -v liquidsoap) /home/opam/root/app; \
    opam depext --list $PACKAGES > /home/opam/root/app/depexts; \
    mkdir -p /home/opam/root/$OPAM_SWITCH_PREFIX/lib; \
    mv $OPAM_SWITCH_PREFIX/share /home/opam/root/$OPAM_SWITCH_PREFIX; \
    mv $OPAM_SWITCH_PREFIX/lib/liquidsoap /home/opam/root/$OPAM_SWITCH_PREFIX/lib



FROM debian:12-slim

# Add PhasecoreX user-entrypoint script
ADD https://raw.githubusercontent.com/PhasecoreX/docker-user-image/master/user-entrypoint.sh /bin/user-entrypoint
RUN chmod +rx /bin/user-entrypoint && /bin/user-entrypoint --init

COPY --from=builder /home/opam/root /

RUN set -eux; \
    sed -i 's/^Components:.*/Components: main contrib non-free/g' /etc/apt/sources.list.d/debian.sources; \
    apt-get update; \
    cat /app/depexts | xargs apt-get install -y --no-install-recommends; \
    rm -rf /var/lib/apt/lists/*; \
    /app/liquidsoap --version

ENTRYPOINT ["/bin/user-entrypoint", "/app/liquidsoap"]
