#!/bin/bash
# ------------------------------------------------------------------
# Day 2 Workshop Completion Cleanup Script
# Run this at END of Day 2 to prepare for Day 3 GitOps
# Removes Day 2 java-webapp resources to prevent conflicts with Day 3
# ------------------------------------------------------------------
set -euo pipefail

echo "🎉 Day 2 Workshop Completion - Preparing for Day 3 GitOps"
echo "📝 Run this script AFTER completing Day 2 workshop"
echo ""

# ============================================================================
# Namespace Detection
# ============================================================================
echo "🔍 Detecting your student namespace..."

# Try to get current namespace from oc context
current_namespace=$(oc config view --minify -o jsonpath='{..namespace}' 2>/dev/null || echo "")

# If no namespace in context, try to detect from environment
if [ -z "$current_namespace" ]; then
    current_namespace=$(echo $HOSTNAME | sed 's/code-server.*//' | sed 's/.*-//' 2>/dev/null || echo "")
fi

# If still no namespace, ask user
if [ -z "$current_namespace" ] || [[ ! "$current_namespace" =~ ^student[0-9]+$ ]]; then
    echo "⚠️  Could not auto-detect your student namespace"
    read -rp "🧑‍🎓 Enter your student namespace (e.g., student01): " current_namespace
    [[ -z "$current_namespace" ]] && { echo "❌ Namespace is required."; exit 1; }
fi

# Validate namespace format
if [[ ! "$current_namespace" =~ ^student[0-9]+$ ]]; then
    echo "❌ ERROR: Invalid namespace format. Expected: student01, student02, etc."
    exit 1
fi

echo "✅ Using namespace: ${current_namespace}"
echo ""

# ============================================================================
# Cleanup Configuration
# ============================================================================
NAMESPACE="${current_namespace}"

echo "🧹 Day 2 Cleanup Configuration:"
echo "   🏷️  Target Namespace: ${NAMESPACE}"
echo "   🎯 Purpose: Remove Day 2 java-webapp to prepare for Day 3 GitOps"
echo "   ✅ Preserves: code-server, namespace, pipeline definitions"
echo ""
read -rp "❓ Proceed with cleanup? (y/n): " CONFIRM
[[ "$CONFIRM" != [yY] ]] && { echo "❌ Cleanup aborted."; exit 1; }

echo ""
echo "🗑️  Starting Day 2 cleanup for namespace: ${NAMESPACE}"

# ============================================================================
# Remove Day 2 Java Webapp Resources
# ============================================================================
echo ""
echo "📦 Removing Day 2 java-webapp deployment resources..."

echo "➡️  Removing java-webapp deployment"
oc delete deployment java-webapp -n "${NAMESPACE}" --ignore-not-found

echo "➡️  Removing java-webapp service"
oc delete service java-webapp -n "${NAMESPACE}" --ignore-not-found

echo "➡️  Removing java-webapp route"
oc delete route java-webapp -n "${NAMESPACE}" --ignore-not-found

echo "➡️  Removing java-webapp imagestream"
oc delete imagestream java-webapp -n "${NAMESPACE}" --ignore-not-found

# ============================================================================
# Clean Up Pipeline Execution Pods
# ============================================================================
echo ""
echo "🧽 Cleaning up completed Day 2 pipeline/build pods..."

echo "➡️  Removing git-clone task pods"
oc delete pod -l tekton.dev/task=git-clone -n "${NAMESPACE}" --ignore-not-found

echo "➡️  Removing maven-build task pods"
oc delete pod -l tekton.dev/task=maven-build -n "${NAMESPACE}" --ignore-not-found

echo "➡️  Removing war-sanity-check task pods"
oc delete pod -l tekton.dev/task=war-sanity-check -n "${NAMESPACE}" --ignore-not-found

echo "➡️  Removing shipwright-trigger task pods"
oc delete pod -l tekton.dev/task=shipwright-trigger -n "${NAMESPACE}" --ignore-not-found

echo "➡️  Removing deploy task pods"
oc delete pod -l tekton.dev/task=deploy -n "${NAMESPACE}" --ignore-not-found

echo "➡️  Removing build-related pods"
oc delete pod -l buildrun.shipwright.io/name -n "${NAMESPACE}" --ignore-not-found

# ============================================================================
# Clean Up Pipeline/Build Runs
# ============================================================================
echo ""
echo "🔄 Removing Day 2 pipeline and build execution history..."

echo "➡️  Removing all PipelineRuns"
oc delete pipelinerun --all -n "${NAMESPACE}" --ignore-not-found

echo "➡️  Removing all TaskRuns"
oc delete taskrun --all -n "${NAMESPACE}" --ignore-not-found

echo "➡️  Removing all BuildRuns"
oc delete buildrun --all -n "${NAMESPACE}" --ignore-not-found

# ============================================================================
# Clean Up Any Existing ArgoCD Applications
# ============================================================================
echo ""
echo "🔄 Cleaning up any existing ArgoCD applications..."

echo "➡️  Removing ArgoCD application: java-webapp-${NAMESPACE} (if exists)"
oc delete application "java-webapp-${NAMESPACE}" -n openshift-gitops --ignore-not-found

# ============================================================================
# Verification
# ============================================================================
echo ""
echo "🔍 Verifying Day 2 cleanup completion..."

echo ""
echo "📋 Current pods in namespace ${NAMESPACE}:"
oc get pods -n "${NAMESPACE}" || echo "No pods found"

echo ""
echo "🔍 Checking for remaining java-webapp resources:"
remaining_resources=$(oc get deployment,service,route -n "${NAMESPACE}" 2>/dev/null | grep java-webapp || echo "")
if [ -z "$remaining_resources" ]; then
    echo "✅ No java-webapp resources found - Day 2 cleanup successful!"
else
    echo "⚠️  Some java-webapp resources still exist:"
    echo "$remaining_resources"
fi

echo ""
echo "🔍 Verifying code-server is still running:"
code_server_pod=$(oc get pods -n "${NAMESPACE}" | grep code-server || echo "")
if [ -n "$code_server_pod" ]; then
    echo "✅ code-server preserved:"
    echo "$code_server_pod"
else
    echo "⚠️  code-server not found - this may be expected depending on setup"
fi

# ============================================================================
# Summary and Next Steps
# ============================================================================
cat <<EOF

================================================================================
🎉 Day 2 Workshop Cleanup Complete for namespace: ${NAMESPACE}
================================================================================

✅ REMOVED (to prevent Day 3 conflicts):
   • Day 2 java-webapp deployment, service, route, imagestream
   • Completed Day 2 pipeline/build pods
   • Day 2 PipelineRuns, TaskRuns, BuildRuns execution history
   • Any existing ArgoCD applications

✅ PRESERVED (still available for Day 3):
   • code-server environment
   • Namespace and basic infrastructure
   • Pipeline/Task definitions (can be reused)
   • RBAC and service accounts

🚀 READY FOR DAY 3 GITOPS:
   Your namespace is now clean and ready for Day 3 GitOps workshop!

📝 NEXT STEPS FOR DAY 3:
   1. Navigate to Day 3 lab directory:
      cd /home/coder/workspace/labs/day3-gitops

   2. Clone Day 3 GitOps repository:
      git clone -b ${NAMESPACE} https://github.com/kevin-biot/argocd
      cd argocd

   3. Run Day 3 setup:
      ./setup-student-pipeline.sh

   4. Follow the copy-paste instructions from the script output

🎯 Day 3 will demonstrate:
   • GitOps deployment workflows with ArgoCD
   • Automatic application synchronization from Git
   • Branch-based environment management
   • Declarative application lifecycle management

================================================================================

EOF
