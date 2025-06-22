#!/bin/bash
# ------------------------------------------------------------------
# Render & apply everything a student needs *except* the two
# “one-shot” objects they must run by hand (BuildRun + PipelineRun).
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
  k8s/deployment.yaml
  k8s/service.yaml               #  ⬅ NEW
  k8s/route.yaml                 #  ⬅ NEW
  tekton/pvc.yaml
  tekton/pipeline.yaml
  tekton/tasks/deploy.yaml
  tekton/tasks/shipwright-trigger.yaml
  shipwright/build/build.yaml
)

# ---------- rendered only (student applies manually) --------------
FILES_RENDER_ONLY=(
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
  # 'oc apply' is idempotent → safe on re-runs, no “AlreadyExists” noise.
  oc apply -n "$NAMESPACE" -f "$DEST_DIR/$(basename "$f")"
done

# ---------------------- student instructions ----------------------
cat <<EOF

🎯 All YAMLs rendered for namespace: $NAMESPACE
📂 Rendered files are in: $DEST_DIR

📌 Next steps for the student
  1.  cd $DEST_DIR

  2.  Trigger a Shipwright build (re-run safe):
        oc delete buildrun --all -n $NAMESPACE --ignore-not-found
        oc create -f buildrun.yaml -n $NAMESPACE

  3.  Kick off the full pipeline (re-run safe):
        oc delete pipelinerun --all -n $NAMESPACE --ignore-not-found
        oc apply  -f pipeline-run.yaml -n $NAMESPACE

🔎 Validate with:
        oc get buildrun.build.shipwright.io -n $NAMESPACE
        oc get pipelinerun                 -n $NAMESPACE
        oc logs -f buildrun/<name>         -n $NAMESPACE   # watch BuildRun
        tkn pr logs -f <PR name>           -n $NAMESPACE   # Tekton (optional)

EOF
