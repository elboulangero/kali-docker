# Official Kali Linux Docker

This Kali Linux Docker image provides a minimal base install of the latest
version of the Kali Linux Rolling Distribution. There are no tools added
to this image, so you will need to install them yourself. 

For details about Kali Linux metapackages, check
<https://www.kali.org/blog/kali-linux-metapackages/>.

# Weekly updates

Docker images are updated weekly and pushed to the Docker Hub at
<https://hub.docker.com/u/kalilinux>.

You can run those images with either Docker or Podman, at your convenience:

```
# Podman
podman run --rm -it kali-rolling
# Docker
docker run --rm -it kalilinux/kali-rolling
```

For more documentation, refer to:
* <https://www.kali.org/docs/containers/using-kali-podman-images/>
* <https://www.kali.org/docs/containers/using-kali-docker-images/>

# How to build those images

The easiest is probably to build via the GitLab infrastructure. All it takes is
to fork the GitLab repository, and let the CI/CD build it for you. Images are
rebuilt every time a commit is pushed, and can be found in the GitLab Registry
that is associated with your fork.

For those who prefer to build locally, there is the script `build.sh`.  A good
starting point is `./build.sh -h`.
