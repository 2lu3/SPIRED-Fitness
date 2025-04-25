ARG DEBIAN_FRONTEND=noninteractive

# 1) model.zip をダウンrpーど
FROM alpine:3.21.3 AS wget-download
RUN apk add --no-cache wget unzip && \
    wget https://zenodo.org/records/10675405/files/model.zip && \
    unzip model.zip -d /opt/model && \
    rm model.zip

# 2) torch hub models をダウンロード
FROM python:3.11.12-slim-bookworm  AS python-download
ENV TORCH_HOME=/opt/torch_cache
RUN mkdir -p $TORCH_HOME && \
    pip install --no-cache-dir torch==2.1.0 && \
    python - <<'PY'
import torch, os
os.environ["TORCH_HOME"] = "/opt/torch_cache"
models = ["esm2_t33_650M_UR50D", "esm2_t36_3B_UR50D"] + \
         [f"esm1v_t33_650M_UR90S_{i}" for i in range(1,6)]
for m in models:
    torch.hub.load("facebookresearch/esm:main", m, trust_repo=True)
PY

# 3) python 仮想環境を作成
FROM python:3.11.12-bookworm AS build
RUN apt-get update \
    && apt-get install -y --no-install-recommends python3-venv \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /opt/spired_env
ENV PATH=/opt/spired_env/bin:$PATH
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir \
    torch==2.1.0 \
    biopython==1.83 \
    click==8.1.7 \
    einops==0.7.0 \
    fair-esm==2.0.0 \
    pandas==2.2.0

# 4) ランタイム
FROM python:3.11.12-slim-bookworm AS final
ENV PATH=/opt/spired_env/bin:$PATH \
    TORCH_HOME=/opt/torch_cache \
    SPIRED_DIR=/opt/spired
WORKDIR $SPIRED_DIR
RUN useradd -ms /bin/bash test && \
    chown -R test:test $SPIRED_DIR $SPIRED_DIR/cache


USER test
COPY --chown=test:test --from=build /opt/spired_env /opt/spired_env
COPY --chown=test:test --from=python-download /opt/torch_cache /opt/torch_cache
COPY --chown=test:test --from=wget-download /opt/model model
COPY scripts/ scripts
COPY run_SPIRED*.py .

ENTRYPOINT ["python","run_SPIRED.py"]
CMD ["--help"]
