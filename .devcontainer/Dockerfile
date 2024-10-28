FROM mcr.microsoft.com/devcontainers/python:1-3.11-bookworm

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
      python3-gst-1.0 libcairo2-dev libgirepository1.0-dev \
      libpango1.0-dev libpulse-dev libsrtp2-dev

RUN pip install PyGObject
