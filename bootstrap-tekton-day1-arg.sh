#!/bin/bash
set -e

NAMESPACE="${1:-student01}"

echo "🔧 Ensuring namespace: $NAMESPACE exists..."
oc get ns "$NAMESPACE" >/dev/null 2>&1 || oc new-project "$NAMESPACE"

echo "📦 Creating PVC in namespace: $NAMESPACE"
cat <<EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF

echo "📥 Installing Tekton Tasks into $NAMESPACE..."

# Apply git-clone task
oc apply -n "$NAMESPACE" -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/git-clone/0.9/git-clone.yaml

# Apply maven task
oc apply -n "$NAMESPACE" -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/maven/0.2/maven.yaml

# Apply kaniko task
oc apply -n "$NAMESPACE" -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/kaniko/0.6/kaniko.yaml

echo "✅ Bootstrap completed for namespace: $NAMESPACE"
