FROM python:3.13-bullseye
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN apt update && apt install gettext -y
RUN apt install vim -y
RUN apt install dnsutils -y
RUN apt install netcat -y

RUN mkdir /code

WORKDIR /code

RUN pip install poetry

# RUN pip install --upgrade 'sentry-sdk[django]'

COPY pyproject.toml poetry.lock ./
COPY README.md /code/

COPY djangoarticleapp /code/djangoarticleapp

RUN poetry check

RUN poetry install

COPY . .
RUN chmod +x /code/start-django.sh

EXPOSE 8000

ENTRYPOINT [ "/code/start-django.sh" ]