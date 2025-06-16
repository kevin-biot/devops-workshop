# Java Webapp Demo

## Overview
This repository contains a simple Java servlet application packaged as a WAR file. The application responds with a basic greeting and includes an index page demonstrating a minimal web front end. It is intended for demonstrations of container build pipelines and Kubernetes deployments.

## Building with Maven
Ensure a JDK and Maven are installed. Run the following command from the repository root:

```bash
mvn package
```

This produces `target/java-webapp.war` which can be used in the provided Dockerfile or deployed directly to a servlet container.

## Deploying to Kubernetes
Kubernetes/OpenShift manifests are provided under the `k8s/` directory. Apply them in order with `kubectl apply -f` or `oc apply -f`:

1. `k8s/namespace.yaml` – creates a namespace for the pipeline resources.
2. `k8s/java-webapp-imagestream.yaml` – OpenShift image stream for the built image.
3. `k8s/rbac/` – roles and bindings required for the pipeline service account.
4. `k8s/deployment.yaml`, `k8s/service.yaml` and `k8s/route.yaml` – deploy the application and expose it via a route.

Before applying the manifests set a namespace variable and substitute it when
applying. For a single file this looks like:

```bash
export NAMESPACE=student05
envsubst < k8s/deployment.yaml | oc apply -f -
```

To process multiple files you can loop over them:

```bash
for f in k8s/*.yaml k8s/rbac/*.yaml; do
  envsubst < "$f" | oc apply -f -
done
```

## Tekton and Shipwright Pipelines
Pipeline definitions reside in the `tekton/` and `shipwright/` directories.

- **tekton/** contains cluster tasks for Git cloning, Maven builds and WAR checks, plus a Task to deploy the manifest. `pipeline.yaml` stitches these tasks together, while `pipeline-run.yaml` shows an example PipelineRun. `pvc.yaml` defines a workspace volume shared across tasks.
- **shipwright/** defines a Shipwright Build (`build.yaml`) using the Buildah strategy and a matching BuildRun (`buildrun.yaml`). The buildstrategy files provide a Buildah-based container build strategy used by the Build.

These files demonstrate how to build and deploy the application using Tekton and Shipwright on OpenShift.

