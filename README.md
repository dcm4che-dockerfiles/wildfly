# WildFly

## Development

### Requirments
- [Docker](https://docs.docker.com/get-docker/)
- [buildx](https://docs.docker.com/buildx/working-with-buildx/)

### Building

Without ffmpeg
```bash
docker build --platform linux/amd64,linux/arm64,linux/arm/v7 -t thetonio96/wildfly:my-tag --push -f Dockerfile .
```

With ffmpeg
```bash
docker build --platform linux/amd64,linux/arm64,linux/arm/v7 -t thetonio96/wildfly:ffmpeg-my-tag --push -f Dockerfile-ffmpeg .
```
