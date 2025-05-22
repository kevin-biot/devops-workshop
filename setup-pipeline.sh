#!/bin/bash

# DevOps Workshop Pipeline Setup Script
echo "🚀 Setting up DevOps Workshop Pipeline..."

# Set variables
NAMESPACE="student01"
PROJECT_NAME="devops-workshop"

# Check if logged into OpenShift
if ! oc whoami &>/dev/null; then
    echo "❌ Please log into OpenShift first: oc login <cluster-url>"
    exit 1
fi

echo "📝 Current user: $(oc whoami)"

# Create or switch to project
echo "🏗️  Creating/switching to project: $NAMESPACE"
oc new-project $NAMESPACE 2>/dev/null || oc project $NAMESPACE

# Apply PVC
echo "💾 Creating Persistent Volume Claim..."
oc apply -f tekton/shared-pvc.yaml -n $NAMESPACE

# Install ClusterTasks (these are cluster-wide)
echo "🔧 Installing ClusterTasks..."
oc apply -f tekton/clustertasks-v1beta1.yaml

# Install Task
echo "📋 Installing Tasks..."
oc apply -f tekton/tasks/apply-deployment.yaml -n $NAMESPACE

# Install Pipeline
echo "🔄 Installing Pipeline..."
oc apply -f tekton/pipeline.yaml -n $NAMESPACE

# Set up RBAC for image building and deployment
echo "🔐 Setting up permissions..."
oc policy add-role-to-user system:image-builder system:serviceaccount:$NAMESPACE:pipeline -n $NAMESPACE
oc policy add-role-to-user edit system:serviceaccount:$NAMESPACE:pipeline -n $NAMESPACE

echo "✅ Setup complete!"
echo ""
echo "🎯 To run the pipeline:"
echo "   oc apply -f tekton/pipelinerun.yaml -n $NAMESPACE"
echo ""
echo "📊 To monitor the pipeline:"
echo "   tkn pipelinerun logs --last -f -n $NAMESPACE"
echo ""
echo "🔍 To check the deployment:"
echo "   oc get pods -n $NAMESPACE"
echo "   oc get svc -n $NAMESPACE"
