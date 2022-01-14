FROM ruby:2.7-buster
LABEL maintainer="GitLab Quality Department <quality@gitlab.com>"

ENV DEBIAN_FRONTEND="noninteractive"
ENV DOCKER_VERSION="17.09.0-ce"

##
# Update APT sources and install dependencies
#
RUN sed -i "s/httpredir.debian.org/ftp.us.debian.org/" /etc/apt/sources.list
RUN apt-get update && apt-get install -y wget unzip xvfb lsb-release git git-lfs

##
# Install Docker
#
RUN wget -q "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz" && \
    tar -zxf "docker-${DOCKER_VERSION}.tgz" && mv docker/docker /usr/local/bin/docker && \
    rm "docker-${DOCKER_VERSION}.tgz"

##
# Install client certificate - Bug in Chrome Headless: https://gitlab.com/gitlab-org/gitlab/-/issues/331492
#
# RUN apt install -y libnss3-tools
# RUN mkdir -p $HOME/.pki/nssdb
# RUN certutil -N -d sql:$HOME/.pki/nssdb
# COPY ./qa/tls_certificates/client/client.pfx /tmp/client.pfx
# RUN pk12util -d sql:$HOME/.pki/nssdb -i /tmp/client.pfx -W ''
# RUN mkdir -p /etc/opt/chrome/policies/managed
# RUN echo '{ "AutoSelectCertificateForUrls": ["{\"pattern\":\"*\",\"filter\":{}}"] }' > /etc/opt/chrome/policies/managed/policy.json
# RUN cat /etc/opt/chrome/policies/managed/policy.json

##
# Install root certificate
#
RUN mkdir -p /usr/share/ca-certificates/gitlab
ADD ./qa/tls_certificates/authority/ca.crt /usr/share/ca-certificates/gitlab/
RUN echo 'gitlab/ca.crt' >> /etc/ca-certificates.conf
RUN chmod -R 644 /usr/share/ca-certificates/gitlab && update-ca-certificates

##
# Install gcloud and kubectl CLI used in Auto DevOps test to create K8s
# clusters
#
RUN export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)" && \
    echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    apt-get update -y && apt-get install google-cloud-sdk kubectl -y

##
# Install Google Chrome version with headless support
# Download from our local S3 bucket, populated by https://gitlab.com/gitlab-org/gitlab-build-images/-/blob/master/scripts/cache-google-chrome
#
# https://s3.amazonaws.com/gitlab-google-chrome-stable
ENV CHROME_VERSION="91.0.4472.77-1"
ENV CHROME_DEB="google-chrome-stable_${CHROME_VERSION}_amd64.deb"
ENV CHROME_URL="https://s3.amazonaws.com/gitlab-google-chrome-stable/${CHROME_DEB}"
RUN curl --silent --show-error --fail -O "${CHROME_URL}" && \
    dpkg -i "./${CHROME_DEB}" || true && \
    apt-get install -f -y && \
    rm -f "./${CHROME_DEB}"

WORKDIR /home/gitlab/qa

# Install qa dependencies or fetch from cache if unchanged
COPY ./qa/Gemfile* /home/gitlab/qa/
RUN bundle install --jobs=$(nproc) --retry=3 --without=development --quiet

##
# Fetch chromedriver based on version of chrome
# Copy rakefile first so that webdriver is not reinstalled on every code change
# https://github.com/titusfortner/webdrivers
COPY ./qa/tasks/webdrivers.rake /home/gitlab/qa/tasks/
RUN bundle exec rake -f tasks/webdrivers.rake webdrivers:chromedriver:update

COPY ./config/initializers/0_inject_enterprise_edition_module.rb /home/gitlab/config/initializers/
# Copy VERSION to ensure the COPY succeeds to copy at least one file since ee/app/models/license.rb isn't present in FOSS
# The [b] part makes ./ee/app/models/license.r[b] a pattern that is allowed to return no files (which is the case in FOSS)
COPY VERSION ./ee/app/models/license.r[b] /home/gitlab/ee/app/models/
COPY ./config/bundler_setup.rb /home/gitlab/config/
COPY ./lib/gitlab.rb /home/gitlab/lib/
COPY ./lib/gitlab/utils.rb /home/gitlab/lib/gitlab/
COPY ./INSTALLATION_TYPE ./VERSION /home/gitlab/

COPY ./qa /home/gitlab/qa

ENTRYPOINT ["bin/test"]
