#!/bin/bash

TAGNAME="mbsemashup-sysml-jupyter-test"

podman build ./ -f Dockerfile.jupyter --tag $TAGNAME


# Test as arbitrary UID (OpenShift assigns random UIDs)
podman run --rm --user 1001:1001 $TAGNAME

# Test with read-only root filesystem (OpenShift best practice)
podman run --rm --read-only --user 1000:1000 $TAGNAME

# Test without capabilities (closer to OpenShift's restricted SCC)
podman run --rm --cap-drop=ALL --user 1000:1000 $TAGNAME

# verify the entrypoint
podman run --rm --user 1000:1000 $TAGNAME jupyter --version
