# Generic chart

## Description

This is a generic chart that can be used for:

- Private HTTP service,
- Public HTTP service,
- Public HTTP service with authorization
- Non HTTP services.

The aim of this chart is to expose the most simple way a generic service that can be used to render the manifests required by Kubernetes to be deployed.

## Options

- `image`: The container image of the service.
- `tag`: The version of the image (image tag).
- `team`: The team ownig this service.
- `environmentType`: The environment where the app is running.
- `namespace`: The namespace of the service, if not set, fallback to the name of the service.
- `environment`: A map of Key value that will end on the environment of the application.
- `secrets`: A map of key value that will end on the environment of the application but will be treated as secrets at kubernetes level.
- `scalability.replicas`: The minimum instances the applications has.
- `scalability.maxReplicas`: The maximum instances the applications has.
- `autoscaleCPUPercent`: Is the threshold of CPU where the cluster will spin new instances.
- `cmdArgs`: A list or arguments to pass to the image.
- `httpService.internalPort`: the port the container app will expose the HTTP service, metrics and health checks
- `httpService.public.enable`: Will enable external access to the service.
- `httpService.public.auth`: Will set OAUTH authentication on the external access.
- `httpService.public.host`: The host the service will be available externally.
- `metrics.enable`: Will enable metrics.
- `metrics.prometheus.path`: Will the the path where pPrometheus will get the metrics.
- `metrics.prometheus.instance`: Is the prometheus instance that will ingest the metrics.
- `resources.memoryMiB`: Are the memory MiB the app will be set as requests and limit.
- `resources.cpuMilli`: Are the CPU millis the app will be set as requests and limit.
- `healthCheck.livePath`: Is the path that will be queried for live health check.
- `healthCheck.readyPath`: Is the path that will be queried for ready health check.
