# This is image version 3.14159
FROM ruby:3.2.2-bookworm

# Install google chrome
ENV GOOGLE_CHROME_VERSION=117.0.5938.132-1
RUN set -eux ; \
    apt-get update -y \
    && curl -Lo /tmp/google-chrome.deb "https://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_${GOOGLE_CHROME_VERSION}_amd64.deb" \
    && apt install /tmp/google-chrome.deb -y --no-install-recommends \
    && rm /tmp/google-chrome.deb \
    && rm -rf /var/lib/apt/lists/*
