FROM mambaorg/micromamba:debian12-slim AS build

ARG DEBIAN_FRONTEND=noninteractive
ARG CONDA_DIR /opt/conda

RUN micromamba install -y -n spired \
        python=3.11 \
        pytorch=2.1.0 \
        biopython=1.83 \
        click=8.1.7 \
        einops=0.7.0 \
        fair-esm=2.0.0 \
        pandas=2.2.0 \
    && micromamba clean --all -y

ENV PATH $CONDA_DIR/envs/spired/bin:$PATH \
    TORCH_HOME /opt/torch_cache

WORKDIR /opt/spired

RUN wget -q https://zenodo.org/records/10675405/files/model.zip && \
    unzip -q model.zip && \
    rm model.zip

RUN python - <<'PY'
import torch, os
os.environ["TORCH_HOME"] = "/opt/torch_cache"
models = ["esm2_t33_650M_UR50D", "esm2_t36_3B_UR50D"] + \
         [f"esm1v_t33_650M_UR90S_{i}" for i in range(1,6)]
for m in models:
    torch.hub.load("facebookresearch/esm:main", m, trust_repo=True)
PY

WORKDIR /opt/app
COPY scripts/ scripts/
COPY run_SPIRED*.py .

FROM ubuntu:22.04

ENV PATH /opt/spired_env/bin:$PATH \
    LD_LIBRARY_PATH /opt/spired_env/lib:$LD_LIBRARY_PATH \
    TORCH_HOME /opt/torch_cache \
    SPIRED_DIR /opt/spired

RUN useradd -ms /bin/bash test
USER test
#RUN echo "conda activate spired_fitness" >> ~/.bashrc && \
#    sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' ~/.bashrc

COPY --chown=test:test --from=build /opt/conda/envs/spired /opt/spired_env
COPY --chown=test:test --from=build /opt/torch_cache /opt/torch_cache
COPY --chown=test:test --from=build /opt/spired /opt/spired
COPY --chown=test:test --from=build /opt/app /opt/app

# Set up SPIRED working directory
WORKDIR $SPIRED_DIR

#RUN bash -c "source /opt/conda/etc/profile.d/conda.sh \
#             && conda activate spired_fitness \
#             && python run_SPIRED.py \
#                    --fasta_file example_spired/test.fasta \
#                    --saved_folder example_spired"

