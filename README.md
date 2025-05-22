# DevOps Workshop - Quick Start Guide

## Prerequisites
- OpenShift cluster access
- `oc` CLI installed
- `tkn` CLI installed (optional, for monitoring)

## Quick Setup

1. **Clone the repository** (students should fork and clone their own copy):
   ```bash
   git clone https://github.com/YOUR-USERNAME/devops-workshop.git
   cd devops-workshop
   ```

2. **Login to OpenShift**:
   ```bash
   oc login <your-cluster-url>
   ```

3. **Run the setup script**:
   ```bash
   chmod +x setup-pipeline.sh
   ./setup-pipeline.sh
   ```

4. **Start the pipeline**:
   ```bash
   oc apply -f tekton/pipelinerun.yaml -n student01
   ```

5. **Monitor the pipeline**:
   ```bash
   tkn pipelinerun logs --last -f -n student01
   ```

## What the Pipeline Does

1. **fetch-source**: Clones your Git repository
2. **build-maven**: Builds the Java WAR file using Maven
3. **build-image**: Creates a container image using Kaniko
4. **war-sanity**: Verifies the WAR file was created correctly
5. **deploy**: Deploys the application to OpenShift

## Customization

Students can customize the pipeline by:
- Modifying `tekton/pipelinerun.yaml` to point to their fork
- Updating the image name to use their namespace
- Changing the Git revision/branch

## Troubleshooting

- Check pipeline logs: `tkn pipelinerun logs --last -f -n student01`
- Check pod status: `oc get pods -n student01`
- View pipeline runs: `tkn pipelinerun list -n student01`
