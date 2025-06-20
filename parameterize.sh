#!/bin/bash
set -euo pipefail

echo "📦 Starting parameterization script..."

# Directories to process
TARGET_DIRS=("k8s" "tekton" "shipwright")

# Create backup directory
BACKUP_DIR="backup_before_param_$(date +%Y%m%d%H%M%S)"
mkdir -p "$BACKUP_DIR"
echo "🗂️  Backing up original files to: $BACKUP_DIR"

# Find and backup all relevant YAML files
for dir in "${TARGET_DIRS[@]}"; do
  find "$dir" -type f -name '*.yaml' | while read -r file; do
    mkdir -p "$BACKUP_DIR/$(dirname "$file")"
    cp "$file" "$BACKUP_DIR/$file"
  done
done

echo "🔁 Phase 1: Replacing 'student01' → '{{NAMESPACE}}'..."
for dir in "${TARGET_DIRS[@]}"; do
  find "$dir" -type f -name '*.yaml' | while read -r file; do
    if grep -q 'student01' "$file"; then
      sed -i '' 's/student01/{{NAMESPACE}}/g' "$file"
      echo "✅ Modified (namespace): $file"
    fi
  done
done

echo "🔁 Phase 2: Rewriting image paths with embedded 'student01'..."
for dir in "${TARGET_DIRS[@]}"; do
  find "$dir" -type f -name '*.yaml' | while read -r file; do
    if grep -q 'image-registry\.openshift-image-registry\.svc:5000/{{NAMESPACE}}/' "$file"; then
      continue  # Already templated
    fi
    if grep -q 'image-registry\.openshift-image-registry\.svc:5000/student01/' "$file"; then
      sed -i '' 's#image-registry\.openshift-image-registry\.svc:5000/student01/#image-registry.openshift-image-registry.svc:5000/{{NAMESPACE}}/#g' "$file"
      echo "✅ Modified (image path): $file"
    fi
  done
done

echo "🎉 All replacements completed. Original files backed up in: $BACKUP_DIR"
