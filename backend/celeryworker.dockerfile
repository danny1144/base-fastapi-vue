FROM python:3.7

ARG env=prod
ARG POETRY_VER=0.12.17

ENV APP_ENV=${env} \
    PYTHONFAULTHANDLER=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONHASHSEED=random \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100 \
    POETRY_VERSION=${POETRY_VER}

RUN     pip install "poetry==$POETRY_VER"

WORKDIR /app/

# Copy only requirements to cache them in docker layer
COPY ./app/pyproject.toml ./app/poetry.lock* /app/

RUN poetry config settings.virtualenvs.create false \
    && poetry install $(test $env = prod && echo "--no-dev") --no-interaction --no-ansi

# Allow installing dev dependencies to run tests

# For development, Jupyter remote kernel, Hydrogen
# Using inside the container:
# jupyter lab --ip=0.0.0.0 --allow-root --NotebookApp.custom_display_url=http://127.0.0.1:8888
ARG INSTALL_JUPYTER=false
RUN bash -c "if [ $INSTALL_JUPYTER == 'true' ] ; then pip install jupyterlab ; fi"

ENV C_FORCE_ROOT=1

COPY ./app /app
WORKDIR /app

ENV PYTHONPATH=/app

COPY ./app/worker-start.sh /worker-start.sh

RUN chmod +x /worker-start.sh

CMD ["bash", "/worker-start.sh"]
