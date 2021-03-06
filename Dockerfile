FROM python:3.8.6-slim-buster as base

RUN apt-get update \
    && apt-get install -y curl \
    && mkdir todo_app \
    && curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python 
RUN ["/bin/bash", "-c", "source /root/.poetry/env"]
ENV PATH="${PATH}:/root/.poetry/bin"
WORKDIR /todo_app
COPY todo_app/poetry.toml todo_app/pyproject.toml todo_app/poetry.lock ./

FROM base as production
EXPOSE 5000
COPY todo_app todo_app
WORKDIR /todo_app
RUN poetry install --no-dev
ENTRYPOINT [ "poetry", "run", "gunicorn", "--config", "gunicorn.conf.py", "app:create_app()" ]

FROM base as development
EXPOSE 5000
RUN poetry install
ENTRYPOINT [ "poetry", "run", "flask", "run", "--host", "0.0.0.0"]

FROM base as test
RUN apt-get install firefox-esr -y
RUN curl -sSL https://github.com/mozilla/geckodriver/releases/download/v0.28.0/geckodriver-v0.28.0-linux64.tar.gz | tar xvz -C /usr/bin
RUN poetry install
ENTRYPOINT [ "poetry", "run", "watchmedo", "shell-command", "--recursive", "--patterns=*.py;*.html", "--command=poetry run pytest tests", "--debug-force-polling", "." ]