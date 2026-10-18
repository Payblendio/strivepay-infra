# Staging VPS

This stack replaces the London Lightsail container service and managed staging database with one `small_3_0` Ubuntu instance.

The old services must not be deleted until all three domains pass HTTPS and application checks against the VPS, and a final database dump has been restored. Runtime integration credentials are preserved unchanged; they are copied into `/opt/strivepay/secrets` and never committed.

Deployments are service-scoped: each application repository builds its own image, transfers it over SSH, loads it as the stable `:staging` tag, and runs `docker compose up -d` for only that service. This keeps API, worker, web, database, and proxy releases independently controllable.

