# Summary

This creates multiple clusters used for testing ARO under different scenarios.


## Quickstart

1. Setup infrastructure, identity, and permissions:

    ```bash
    make setup
    ```

1. Create cluster associated with infra:

> **NOTE**: to setup a cluster explicitly, use the USE_CASE variable.  Each use case
> exists in the `scripts/clusters` directory (without the .sh extension)

    ```bash
    make install
    ```

OR

    ```bash
    USE_CASE=miwi_private_api make install
    ```
