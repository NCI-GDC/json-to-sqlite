ARG REGISTRY=docker.osdc.io/ncigdc
ARG BASE_CONTAINER_VERSION=latest

FROM ${REGISTRY}/python3.9-builder:${BASE_CONTAINER_VERSION} as builder

COPY ./ /json_to_sqlite

WORKDIR /json_to_sqlite

RUN pip install tox && tox -e build

FROM ${REGISTRY}/python3.9:${BASE_CONTAINER_VERSION}

LABEL org.opencontainers.image.title="json_to_sqlite" \
      org.opencontainers.image.description="json_to_sqlite" \
      org.opencontainers.image.source="https://github.com/NCI-GDC/json-to-sqlite" \
      org.opencontainers.image.vendor="NCI GDC"

COPY --from=builder /json_to_sqlite/dist/*.whl /json_to_sqlite/
COPY requirements.txt /json_to_sqlite/

WORKDIR /json_to_sqlite

RUN pip install --no-deps -r requirements.txt \
	&& pip install --no-deps *.whl \
	&& rm -f *.whl requirements.txt

USER app

ENTRYPOINT ["json_to_sqlite"]

CMD ["--help"]
