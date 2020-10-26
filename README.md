# kahoy-helm-example

[![Build Status][deploy-image]][deploy-url] [![Build Status][schedule-sync-all-image]][schedule-sync-all-url] [![Build Status][docker-image-image]][docker-image-url]

This example shows a production-ready, simple and reliable way of deploying multiple apps on different environments based on Kubernetes.

## Features

- Multiple environments (staging and production).
- Multiple applications.
- Each app can have different configuration and version.
- Scalable to hundreds of apps (Uses a generic Helm chart).
- Optional configuration inheritance.
- Waits until deployed/deleted resources are ready.
- Deployment flow through Git and PRs.
- Scheduled syncs to fix _manual_ changes.
- Use Github actions as CI.

## How does it work

- We will have a generic [Helm] chart with multiple options. Each app can configure these options.
- We will use a generation script that will convert all these options into Kubernetes app manifests.
- We will use [Kahoy] to sync these manifests on Kubernetes (create, update and delete).
- We will have a wait script that uses [Kubedog] to wait for resources on the cluster to be ready.
- We will use Github actions CI to generate, deploy and wait.

### Step 1: Kubernetes manifests generation

We have a generic helm chart ready to be used to generate the required manifests to deploy a service on Kubernetes.

We are only using helm for rendering, the generic chart comes with:

- Deployment + service
- Autoscaling
- Ingress
- Monitoring
- ...

We have set default values, so applications only need to configure whatever they required. This will create our abstraction layer so users don't need to craft huge YAML manifests to deploy a generic service.

- [`./charts`](charts/): Generic [Helm] chart.
- [`./_gen`](_gen/): Generated manifests (these are the ones that will be deployed).
- [`./services`](services/): Our applications, with their version, configuration.

#### Services structure

Our services have this structure `services/{SERVICE}/{ENV}`, e.g:

```text
├── app1
│   ├── staging
│   └── production
└── app2
    └── production
```

This will generate 3 applications:

- `app1` in `staging`.
- `app1` in `production`.
- `app2` in `production`.

To configure the services, we need `config.yaml` and `version` files to generate the required Kubernetes YAMLs.

The envs can inherit the app level configuration and version if they don't redefine values, however `config.yaml` file must exist on app and env level (can be empty). e.g:

```text
├── app1
│   ├── config.yaml         `app1-root-config`
│   ├── production
│   │   ├── config.yaml     `app1-prod-config`
│   │   └── version         `app1-prod-version`
│   ├── staging
│   │   └── config.yaml     `app1-staging-config`
│   └── version             `app1-root-version`
└── app2
    ├── config.yaml         `app2-root-config`
    └── production
        ├── config.yaml     `app2-prod-config`
        └── version         `app2-prod-version`
```

This would produce this:

- app1 production: `app1-root-config` + `app1-prod-config` and `app1-prod-version`.
- app1 staging: `app1-root-config` + `app1-staging-config` and `app1-root-version`.
- app2 production: `app2-root-config` + `app2-prod-config` and `app2-prod-version`.

#### Generated structure

We want to deploy the apps by env, so, to give flexibility, we are generating the envs in `_gen/{ENV}/{SERVICE}` structure. e.g:

```text
./_gen/
├── production
│   ├── app1
│   │   └── resources.yaml
│   └── app2
│       └── resources.yaml
└── staging
    └── app1
        └── resources.yaml
```

Now to deploy to different envs we can use `_gen/production` and `_gen/staging`, or if we add more envs, `_gen/xxxxxx`.

#### How to generate

With `make generate` Will regenerate everything, if any of the resources has been deleted (e.g an application, and ingress...), these will be removed from the generated files.

All this generation logic can be checked in [`scripts/generate.sh`](scripts/generate.sh).

### Step 2: Deploy to Kubernetes

We will use [Kahoy] to deploy to Kubernetes. [Kahoy] is a great tool for raw manifests, it handles the changes. these are the main features we need:

- Understands Kubernetes resources.
- Has dry-run and diff stages.
- Can deploys only the changes between 2 states (old and new).
- Garbage collection.
- Uses kubectl under the hoods to deploy, no magic.

This simplifies everything because we don't depend on a specific tool, we are deploying Raw kubernetes manifests in a smart way:

All the dpeloy commands can be see in [`scripts/deploy.sh`](scripts/deploy.sh).

#### State store on Kubernetes

We are using [Kahoy Kubernetes state storage][kahoy-kubernetes]. This is how Kahoy knows what needs to deploy/delete. For this Kahoy has a storage ID.

We will use a different ID per environment. This way if we deploy only Production manifests, Kahoy will not detect the staging manifests as they have dissapear and needs to garbage collect.

Check [this][storage-id-example] to see where is the ID specificed.

### Step 3: Deployment Feedback

Deploy feedback means the feedback that we get after a deployment, not everyone wants this, but some companies are used to wait until the deployment is ready to mark the deployment as good or bad.

[Kahoy] solves this by giving the user an optional report of what applied. With this report we can know what we need to wait for.

To wait we will use [Kubedog], Kubedog knows how to wait Kubernetes core workloads, these are `Deployments`, `StatefulSets`, `Jobs` and `Daemonsets`.

So in a few words, we will take the Kahoy's [report output][kahoy-report], and pass it through [Kubedog] so it will wait until all the resources are ready (e.g replicas of a deployment updated).

We also can wait for deleted resources, for this, we use `kubetcl wait`.

All this waiting logic can be checked in [`scripts/wait.sh`](scripts/wait.sh).

## CI

We have used Github actions for these example but other CI would work too (e.g Gitlab CI).

We have set 2 workflows:

- PR based
- Scheduled (cron style).

The PR based workflow will execute generate the manifests and execute a kubernetes dry-run+diff with only the changed Kubernetes resources. This will be made for Production and staging environments separetly.

When merged, it will execute the same as before but after the dry-run+diff, the real deploy, and then will wait for the resources.

On the other hand the scheduled pipeline contrary to the PR, it will sync all resources, not only the changed ones. This ensures the manually changed resources on the resources handled by Kahoy are overwritten. This will happen every 12 hours.

### Examples

#### Add a new app (create)

- [PR](https://github.com/slok/kahoy-helm-example/pull/6)
- [Dry-run](https://github.com/slok/kahoy-helm-example/runs/1304427783)
- [Deploy and wait](https://github.com/slok/kahoy-helm-example/runs/1304436794)

#### Fix ingress (change)

- [PR](https://github.com/slok/kahoy-helm-example/pull/7)
- [Dry-run](https://github.com/slok/kahoy-helm-example/runs/1304464224)
- [Deploy and wait](https://github.com/slok/kahoy-helm-example/runs/1304469985)

#### Remove ingress (garbage collection)

- [PR](https://github.com/slok/kahoy-helm-example/pull/8)
- [Dry-run](https://github.com/slok/kahoy-helm-example/runs/1304477194)
- [Deploy and wait](https://github.com/slok/kahoy-helm-example/runs/1304482455)

#### Remove app (delete + create)

- [PR](https://github.com/slok/kahoy-helm-example/pull/9)
- [Dry-run](https://github.com/slok/kahoy-helm-example/runs/1304487157)
- [Deploy and wait](https://github.com/slok/kahoy-helm-example/runs/1304494947)

#### Scheduled pipeline

- [Production deploy](https://github.com/slok/kahoy-helm-example/runs/1306338587)
- [Staging deploy](https://github.com/slok/kahoy-helm-example/runs/1306338620)

[deploy-image]: https://github.com/slok/kahoy-helm-example/workflows/deploy/badge.svg
[deploy-url]: https://github.com/slok/kahoy-helm-example/actions?query=workflow%3Adeploy
[docker-image-image]: https://github.com/slok/kahoy-helm-example/workflows/docker-image/badge.svg
[docker-image-url]: https://github.com/slok/kahoy-helm-example/actions?query=workflow%3Adocker-image
[schedule-sync-all-image]: https://github.com/slok/kahoy-helm-example/workflows/Schedule%20sync%20all/badge.svg
[schedule-sync-all-url]: https://github.com/slok/kahoy-helm-example/actions?query=workflow%3A%22Schedule+sync+all%22
[helm]: https://github.com/helm/helm
[kahoy]: https://github.com/slok/kahoy
[kubedog]: https://github.com/werf/kubedog
[kahoy-kubernetes]: https://docs.kahoy.dev/topics/provider/kubernetes/
[storage-id-example]: https://github.com/slok/kahoy-helm-example/blob/bee08ed0c63e1224544d990bd2683ae66d4ba4b7/scripts/deploy.sh#L23
[kahoy-report]: https://docs.kahoy.dev/topics/report/
