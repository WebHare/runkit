# WebHare on arm64
WARNING: arm64 is experimental. DO NOT RUN IN PRODUCTION.

- We're not regularly publishing an arm64 version to the podman registries
- We do not run continuous integration tests for arm64 WebHare

But if you really need a pihare:

## Building the images

Given a WebHare source tree, a checked out baseimage and proxy project. Update repository as needed, but please do not name it 'webhare'
or any obvious derivative to avoid confusion (especially if we do start to provide official arm64 builds in the future)

You can build your own images or use the ones we built:
```bash
# Build WebHare
wh buildcontainer
podman image tag localhost/webhare/platform:devbuild unilynx/pihare-platform:latest
podman login docker.io
podman push unilynx/pihare-platform:latest

# Build the proxy
cd ~/projects/baseimage
 ./build.sh ubuntu-20
podman tag docker.io/webhare/baseimage:ubuntu-20-devbuild docker.io/webhare/baseimage:ubuntu-20
cd ~/projects/proxy
./build.sh --nopull
podman tag docker.io/webhare/proxy:devbuild unilynx/pihare-proxy:latest
podman push unilynx/pihare-proxy:latest
```

Installing on a Pi:

```bash
# First window
sudo -i
curl https://gitlab.com/webhare/runkit/-/raw/main/install.sh | bash
runkit create-server --default --image docker.io/unilynx/pihare-platform pihare
runkit @pihare run-webhare

# Second window
sudo -i
mkdir -p /opt/runkit-data/_proxy
echo docker.io/unilynx/pihare-proxy:latest > /opt/runkit-data/_proxy/container.image
runkit run-proxy

# Third window
sudo -i
wh-pihare webserver addbackend https://myserver.example.org/
wh-pihare ssl certbot myserver.example.org
wh-pihare users adduser --password secret --sysop sysop@example.nl
```
