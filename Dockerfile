# Combined Dockerfile for CrunchyData Postgres with VectorChord and pgvecto.rs


# --- Builder for VectorChord ---

ARG PG_MAJOR=16
FROM ubuntu:22.04 AS vchord_builder
ARG PG_MAJOR=16
ARG VECTORCHORD_VERSION=0.4.3
ARG TARGETARCH
RUN apt-get update && apt-get install -y curl unzip
WORKDIR /tmp
# Download VectorChord release matching the requested version and architecture
RUN set -eux; \
	case "${TARGETARCH:-amd64}" in \
	  amd64) arch_str='x86_64-linux-gnu' ;; \
	  arm64) arch_str='aarch64-linux-gnu' ;; \
	  aarch64) arch_str='aarch64-linux-gnu' ;; \
	  *) arch_str='x86_64-linux-gnu' ;; \
	esac; \
	url="https://github.com/tensorchord/VectorChord/releases/download/${VECTORCHORD_VERSION}/postgresql-${PG_MAJOR}-vchord_${VECTORCHORD_VERSION}_${arch_str}.zip"; \
	echo "Attempting to download $url"; \
	curl --fail -o vchord.zip -sSL "$url"; \
	unzip -d vchord_raw vchord.zip; \
	mkdir -p /vchord; \
	if [ -d "vchord_raw/pkglibdir" ]; then \
		cp vchord_raw/pkglibdir/vchord.so /vchord/ && \
		cp vchord_raw/sharedir/extension/vchord*.sql /vchord/ && \
		cp vchord_raw/sharedir/extension/vchord.control /vchord/ ; \
	else \
		cp vchord_raw/vchord.so /vchord/ && \
		cp vchord_raw/vchord*.sql /vchord/ && \
		cp vchord_raw/vchord.control /vchord/ ; \
	fi

# --- Builder for pgvecto.rs ---

ARG ALPINE_VERSION=3.21.3
FROM alpine:3.21.3 AS pgvectors_builder
ARG PG_MAJOR=16
RUN apk add --no-cache curl alien rpm binutils xz
WORKDIR /tmp
# Use the latest valid asset for PG16 and amd64
RUN curl --fail -o pgvectors.deb -sSL \
	https://github.com/tensorchord/pgvecto.rs/releases/download/v0.4.0/vectors-pg16_0.4.0_amd64.deb \
	&& alien -r pgvectors.deb \
	&& rm -f pgvectors.deb
RUN rpm2cpio /tmp/*.rpm | cpio -idmv

# --- Final image: CrunchyData Postgres ---
FROM registry.developers.crunchydata.com/crunchydata/crunchy-postgres:ubi9-16.8-2516
ARG PG_MAJOR=16
# Note: pgvector extension is already included in the CrunchyData base image
USER root
# VectorChord
COPY --chown=root:root --chmod=755 --from=vchord_builder /vchord/vchord.so /usr/pgsql-${PG_MAJOR}/lib/
COPY --chown=root:root --chmod=755 --from=vchord_builder /vchord/vchord*.sql /usr/pgsql-${PG_MAJOR}/share/extension/
COPY --chown=root:root --chmod=755 --from=vchord_builder /vchord/vchord.control /usr/pgsql-${PG_MAJOR}/share/extension/
# pgvecto.rs
# Copy any extracted pgvectors artifacts regardless of the exact postgresql/<major>/ path
COPY --chown=root:root --chmod=755 --from=pgvectors_builder /tmp/usr/lib/postgresql/*/lib/vectors.so /usr/pgsql-${PG_MAJOR}/lib/
COPY --chown=root:root --chmod=755 --from=pgvectors_builder /tmp/usr/share/postgresql/*/extension/vectors* /usr/pgsql-${PG_MAJOR}/share/extension/
# Set default user to postgres (numeric ID 26)
USER 26
