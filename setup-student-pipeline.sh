#!/bin/bash
# ------------------------------------------------------------------
# Render & apply everything a student needs *except* the two
# "one-shot" objects they must run by hand (BuildRun + PipelineRun).
# ------------------------------------------------------------------
set -euo pipefail
echo "🔧 Student Pipeline Setup Script"

read -rp "🧑‍🎓  Enter student namespace: " NAMESPACE
read -rp "🌐  Enter Git repo URL [default: https://github.com/kevin-biot/devops-workshop.git]: " REPO_URL
REPO_URL=${REPO_URL:-https://github.com/kevin-biot/devops-workshop.git}
[[ -z "$NAMESPACE" ]] && { echo "❌ Namespace is required."; exit 1; }

echo -e "\n📁 Rendering YAMLs for:"
echo "   🏷️  Namespace: $NAMESPACE"
echo "   📦 Git Repo:  $REPO_URL"
read -rp "❓ Proceed with these values? (y/n): " CONFIRM
[[ "$CONFIRM" != [yY] ]] && { echo "❌ Aborted."; exit 1; }

DEST_DIR="rendered_${NAMESPACE}"
mkdir -p "$DEST_DIR"

# ---------- files that will be rendered **and** applied ----------
FILES_RENDER_AND_APPLY=(
  k8s/rbac/pipeline-app-role.yaml
  k8s/rbac/pipeline-app-binding.yaml
  k8s/java-webapp-imagestream.yaml
  # k8s/deployment.yaml           #  ⬅ MOVED to pipeline-only deployment
  k8s/service.yaml               #  ⬅ NEW
  k8s/route.yaml                 #  ⬅ NEW
  # tekton/pvc.yaml              #  ⬅ REMOVED - PVC already created by deploy-students.sh
  tekton/pipeline.yaml
  shipwright/build/build.yaml
)

# ---------- tekton tasks applied per namespace (was ClusterTasks) ----------
TEKTON_NAMESPACE_TASKS=(
  tekton/tasks/git-clone.yaml
  tekton/tasks/maven-build.yaml  
  tekton/tasks/war-sanity-check.yaml
)

# ---------- rendered only (student applies manually) --------------
FILES_RENDER_ONLY=(
  tekton/pvc.yaml                  #  ⬅ MOVED HERE - render for reference but don't apply
  k8s/deployment.yaml              #  ⬅ ADDED - pipeline will create deployment
  shipwright/build/buildrun.yaml
  tekton/pipeline-run.yaml
)

echo -e "\n🛠️  Rendering files into: $DEST_DIR"
for f in "${FILES_RENDER_AND_APPLY[@]}" "${FILES_RENDER_ONLY[@]}"; do
  tgt="$DEST_DIR/$(basename "$f")"
  sed -e "s|{{NAMESPACE}}|$NAMESPACE|g" \
      -e "s|{{GIT_REPO_URL}}|$REPO_URL|g" \
      "$f" > "$tgt"
  echo "✅ Rendered: $tgt"
done

echo -e "\n🚀 Applying initial resources to namespace: $NAMESPACE"
for f in "${FILES_RENDER_AND_APPLY[@]}"; do
  echo "➡️  Applying $(basename "$f")"
  # 'oc apply' is idempotent → safe on re-runs, no "AlreadyExists" noise.
  oc apply -n "$NAMESPACE" -f "$DEST_DIR/$(basename "$f")"
done

# ---------- tekton tasks applied directly (no templating) ----------
TEKTON_TASKS=(
  tekton/tasks/deploy.yaml
  tekton/tasks/shipwright-trigger.yaml
)

echo -e "\n🎯 Applying Tekton tasks (no templating needed):"
for f in "${TEKTON_TASKS[@]}"; do
  echo "➡️  Applying $(basename "$f")"
  oc apply -n "$NAMESPACE" -f "$f"
done

echo -e "\n🎯 Applying namespace-specific tasks (was ClusterTasks):"
for f in "${TEKTON_NAMESPACE_TASKS[@]}"; do
  echo "➡️  Applying $(basename "$f") to namespace $NAMESPACE"
  oc apply -n "$NAMESPACE" -f "$f"
done

# ---------------------- student instructions ----------------------
cat <<EOF

🎯 All YAMLs rendered for namespace: $NAMESPACE
📂 Rendered files are in: $DEST_DIR

🌐 Your app will be available at:
      https://\$(oc get route java-webapp -n $NAMESPACE -o jsonpath='{.spec.host}')

📌 Next steps for the student
  1.  cd $DEST_DIR

  2.  Run the complete CI/CD pipeline (handles build and deployment):
        oc delete pipelinerun --all -n $NAMESPACE --ignore-not-found
        oc apply -f pipeline-run.yaml -n $NAMESPACE

🔎 Validate with:
        oc get buildrun -n $NAMESPACE
        oc get pipelinerun -n $NAMESPACE
        tkn pipelinerun list -n $NAMESPACE               # list all pipeline runs
        
        # Watch BuildRun logs:
        oc get pods -n $NAMESPACE | grep buildrun        # find buildrun pod name
        oc logs -f <buildrun-pod-name> -n $NAMESPACE     # watch BuildRun logs
        
        # Watch PipelineRun logs (multiple options):
        tkn pipelinerun logs java-webapp-run -f -n $NAMESPACE    # using tkn CLI (recommended)
        tkn pipelinerun logs -f -n $NAMESPACE            # follow latest pipelinerun
        oc logs -f pipelinerun/java-webapp-run -n $NAMESPACE     # using oc logs

🌐 Access your deployed application:
        oc get route java-webapp -n $NAMESPACE           # get the external URL
        oc get pods -n $NAMESPACE -l app=java-webapp     # check app pod status
        oc get svc java-webapp -n $NAMESPACE             # verify service endpoints
        
        # Test internal connectivity:
        curl java-webapp:80
        
        # Get external URL and test:
        export APP_URL="https://\$(oc get route java-webapp -n $NAMESPACE -o jsonpath='{.spec.host}')"
        echo "App URL: \$APP_URL"
        curl -k \$APP_URL

EOF
