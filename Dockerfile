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
dnf clean all
EOF

COPY . /json_to_sqlite

WORKDIR /json_to_sqlite

# Keep pip/tox isolated from RPM-installed Python packages
RUN <<EOF
python3 -m venv /opt/build-venv
/opt/build-venv/bin/python -m pip install --upgrade pip
/opt/build-venv/bin/python -m pip install tox
/opt/build-venv/bin/tox -e build
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
python3 -m pip install --no-cache-dir --no-deps --ignore-installed -r requirements.txt
python3 -m pip install --no-cache-dir --no-deps --ignore-installed *.whl
rm -f *.whl requirements.txt
EOF

CMD ["json_to_sqlite", "--help"]
