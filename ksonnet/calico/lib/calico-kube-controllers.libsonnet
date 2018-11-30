{
  local secret = $.core.v1.secret,

  calicoSecret:
    secret.new('calico', {
      // Populate the following files with etcd TLS configuration if desired, but leave blank if
      // not using TLS for etcd.
      // This self-hosted install expects three files with the following names.  The values
      // should be base64 encoded strings of the entire contents of each file.
      // etcd-key: null
      // etcd-cert: null
      // etcd-ca: null
    }),

  local policyRule = $.rbac.v1beta1.policyRule,

  calicoKubeControllersRBAC: $.util.rbac("calico-kube-controllers", [
    policyRule.new() +
    policyRule.withApiGroups(["", "extensions"]) +
    policyRule.withResources(["pods", "namespaces", "networkpolicies", "nodes", "serviceaccounts"]) +
    policyRule.withVerbs(["watch", "list"]),

    policyRule.new() +
    policyRule.withApiGroups(["networking.k8s.io"]) +
    policyRule.withResources(["networkpolicies"]) +
    policyRule.withVerbs(["watch", "list"]),
  ]),

  calicoKubeControllersConfig:: {
    ETCD_ENDPOINTS: $._config.etcdEndpoints,
    ETCD_CA_CERT_FILE: $._config.etcdCACertFile,
    ETCD_KEY_FILE: $._config.etcdKeyFile,
    ETCD_CERT_FILE: $._config.etcdCertFile,
    ENABLED_CONTROLLERS: $._config.enabledControllers,
  },

  local configMap = $.core.v1.configMap,

  calicoKubeControllersConfigMap:
    configMap.new("calico-kube-controllers") +
    configMap.withData($.calicoKubeControllersConfig),

  local container = $.core.v1.container,
  local envFrom = container.envFromType,

  calicoKubeControllersContainer::
    container.new("calico-kube-controllers", $._images.calicoKubeControllers) +
    container.withEnvFrom(
      envFrom.new() +
      envFrom.mixin.configMapRef.withName("calico-kube-controllers"),
    ) +
    container.mixin.readinessProbe.exec.withCommand(["/usr/bin/check-status", "-r"]),

  local deployment = $.apps.v1beta1.deployment,
  local toleration = $.core.v1.toleration,

  calicoKubeControllersDeployment:
    deployment.new("calico-kube-controllers", $._config.kubeControllersReplicas, [$.calicoKubeControllersContainer]) +
    deployment.mixin.spec.template.spec.withTolerations([
      toleration.new() +
      toleration.withKey("CriticalAddonsOnly") +
      toleration.withOperator("Exists"),

      toleration.new() +
      toleration.withKey("node-role.kubernetes.io/master") +
      toleration.withEffect("NoSchedule"),
    ]) +
    deployment.mixin.spec.template.spec.withHostNetwork(true) +
    deployment.mixin.spec.template.spec.withServiceAccountName("calico-kube-controllers") +
    deployment.mixin.metadata.withAnnotations({ "scheduler.alpha.kubernetes.io/critical-pod": "" }) +
    $.util.secretVolumeMount("calico", "/calico-secrets", 400),
}
