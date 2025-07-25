# Manual tests

Tests that require manual execution, eg because they rely on state outside the
repository. (These tests are not about documentation)

```bash
# Test downloading from the public repository
~/projects/webhare-runkit/tests/manual/install-from-public.sh
```

## Installing a container based webhare
Not automated yet...

```bash
podman machine start
runkit create-server --image release/5.2 test-container-server
```


TODO:
- build two servers. verify they each have a unique container.ipv4
