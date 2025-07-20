# Tekton 1.19 Pipeline Compatibility Updates

## BREAKING CHANGE: Tekton 1.19 Resolver Requirements

**Date:** January 2025  
**Issue:** DOB-87  
**Impact:** Critical - Previous migration strategy was incomplete

### Problem Summary

The initial Tekton 1.19 migration strategy that involved adding `apiVersion: tekton.dev/v1` and `kind: Task` to taskRef definitions was **fundamentally flawed**. This approach caused Tekton to treat regular tasks as CustomRuns, leading to pipeline failures.

### Root Cause Analysis

1. **Tekton 1.19 Controller Bug**: When explicit `apiVersion/kind` are provided in taskRef, the controller incorrectly routes these to the CustomRun reconciler instead of TaskRun reconciler
2. **ClusterTask Deprecation**: ClusterTasks are being phased out in favor of Tekton Resolvers
3. **Documentation Gap**: Official migration guides didn't clearly explain the resolver requirement

### Required Fix: Tekton Resolvers

**OLD (Broken) Syntax:**
```yaml
taskRef:
  name: git-clone
  kind: Task                    # ← This breaks everything!
  apiVersion: tekton.dev/v1
```

**NEW (Working) Syntax:**
```yaml
taskRef:
  resolver: cluster             # ← Required for Tekton 1.19+
  params:
    - name: kind
      value: task
    - name: name
      value: git-clone
    - name: namespace
      value: {{NAMESPACE}}       # ← Student namespace
```

### Implementation Changes

1. **Pipeline Template Updated**: `tekton/pipeline.yaml` now uses cluster resolver syntax
2. **Task Installation**: All tasks installed per-namespace (no ClusterTasks)
3. **Templating Preserved**: `{{NAMESPACE}}` templating continues to work correctly

### Migration Impact

- **Workshop Setup**: Students now get isolated task copies in their namespaces
- **Security Improvement**: No cluster-wide task pollution
- **Compatibility**: Works with Tekton 1.19+ and future versions
- **Performance**: No change in pipeline execution time

### Testing Status

✅ ClusterTask removal  
✅ Per-namespace task installation  
✅ Resolver syntax implementation  
✅ Template variable replacement  
🔄 Student environment validation (in progress)

---

**Previous documentation sections remain valid below this point...**

