ARG REPOSITORY=docker.osdc.io
ARG BUILDER_TAG=3.1.0

FROM ${REPOSITORY}/ncigdc/amzn2023-builder:${BUILDER_TAG} AS builder

RUN <<EOF
dnf update --refresh --best --allowerasing -y
dnf --assumeyes install \
    python3 \
    python3-pip \
    python3-devel \
    gcc \
    git
EOF

COPY . /json_to_sqlite

WORKDIR /json_to_sqlite

RUN <<EOF
python3 -m pip install --upgrade pip
python3 -m pip install tox
tox -e build
EOF


FROM ${REPOSITORY}/ncigdc/amzn2023:${BUILDER_TAG}

LABEL org.opencontainers.image.title="json_to_sqlite" \
      org.opencontainers.image.description="json_to_sqlite" \
      org.opencontainers.image.source="https://github.com/NCI-GDC/json-to-sqlite" \
      org.opencontainers.image.vendor="NCI GDC"

RUN <<EOF
dnf install -y \
    python3 \
    python3-pip

dnf clean all
rm -rf /var/cache/dnf /tmp/* /var/tmp/*
EOF

COPY --from=builder /json_to_sqlite/dist/*.whl /json_to_sqlite/
COPY requirements.txt /json_to_sqlite/

WORKDIR /json_to_sqlite

RUN <<EOF
python3 -m pip install --no-cache-dir --no-deps -r requirements.txt
python3 -m pip install --no-cache-dir --no-deps *.whl
rm -f *.whl requirements.txt
EOF

CMD ["json_to_sqlite", "--help"]
