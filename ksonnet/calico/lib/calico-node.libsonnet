{
  local policyRule = $.rbac.v1beta1.policyRule,

  calicoNodeRBAC: $.util.rbac("calico-node", [
    policyRule.new() +
    policyRule.withApiGroups([""]) +
    policyRule.withResources(["pods", "namespaces") +
    policyRule.withVerbs(["get"),

    policyRule.new() +
    policyRule.withApiGroups([""]) +
    policyRule.withResources(["nodes"]) +
    policyRule.withVerbs(["patch"]),
  ]),

  calicoNodeConfig:: {
    CALICO_IPV4POOL_CIDR: $._config.calicoIPv4PoolCIDR,
    ETCD_ENDPOINTS: $._config.etcdEndpoints,
    ETCD_CA_CERT_FILE: $._config.etcdCACertFile,
    ETCD_KEY_FILE: $._config.etcdKeyFile,
    ETCD_CERT_FILE: $._config.etcdCertFile,
    FELIX_IPINIPMTU: $._config.vethMTU,

    CALICO_BACKEND: "bird",
    CALICO_IPV4POOL_IPIP: "Always",
    CALICO_DISABLE_FILE_LOGGING: "true",
    CLUSTER_TYPE: "k8s,bgp",
    IP: "autodetect",
    FELIX_DEFAULTENDPOINTTOHOSTACTION: "ACCEPT",
    FELIX_IPV6SUPPORT: "false",
    FELIX_LOGSEVERITYSCREEN: "info",
    FELIX_HEALTHENABLED: "true",
  },

  calicoInstallCNIConfig:: {
    # Name of the CNI config file to create.
    CNI_CONF_NAME: "10-calico.conflist",
    # The location of the Calico etcd cluster.
    ETCD_ENDPOINTS: $._config.etcdEndpoints,
    # The CNI network config to install on each node.
    CNI_NETWORK_CONFIG: |||
      {
        "name": "k8s-pod-network",
        "cniVersion": "0.3.0",
        "plugins": [
          {
            "type": "calico",
            "log_level": "info",
            "etcd_endpoints": "__ETCD_ENDPOINTS__",
            "etcd_key_file": "__ETCD_KEY_FILE__",
            "etcd_cert_file": "__ETCD_CERT_FILE__",
            "etcd_ca_cert_file": "__ETCD_CA_CERT_FILE__",
            "mtu": __CNI_MTU__,
            "ipam": {
                "type": "calico-ipam"
            },
            "policy": {
                "type": "k8s"
            },
            "kubernetes": {
                "kubeconfig": "__KUBECONFIG_FILEPATH__"
            }
          },
          {
            "type": "portmap",
            "snat": true,
            "capabilities": {"portMappings": true}
          }
        ]
      }
    |||,
    # CNI MTU Config variable
    CNI_MTU: $._config.vethMTU,
  },

  local configMap = $.core.v1.configMap,

  calicoNodeConfigMap:
    configMap.new("calico-node") +
    configMap.withData($.calicoNodeConfig),

  cniNetworkConfigMap:
    configMap.new("calico-install-cni") +
    configMap.withData($.calicoInstallCNIConfig),

  local container = $.core.v1.container,
  local envFrom = container.envFromType,

  calicoNodeContainer::
    container.new("calico-node", $._images.calicoNode) +
    container.mixin.livenessProbe.httpGet.withPath("/liveness") +
    container.mixin.livenessProbe.httpGet.withPort(9099) +
    container.mixin.livenessProbe.httpGet.withScheme("HTTP") +
    container.mixin.livenessProbe.httpGet.withHost("localhost") +
    container.mixin.livenessProbe.withFailureThreshold(5) +
    container.mixin.livenessProbe.withInitialDelaySeconds(60) +
    container.mixin.livenessProbe.withSuccessThreshold(1) +
    container.mixin.livenessProbe.withTimeoutSeconds(5) +
    container.mixin.readinessProbe.exec.withCommand(["/bin/calico-node", "-bird-ready", "-felix-ready"]) +
    container.mixin.resources.withRequests({ cpu: "250m" }) +
    container.mixin.securityContext.withPrivileged(true) +
    container.withEnvFrom(
      envFrom.new() +
      envFrom.mixin.configMapRef.withName("calico-node"),
    ),

  calicoInstallCNIContainer::
    container.new("calico-install-cni", $._images.calicoInstallCNI) +
    container.withCommand(["/install-cni.sh"]) +
    container.withEnvFrom(
      envFrom.new() +
      envFrom.mixin.configMapRef.withName("calico-install-cni"),
    ),

  local daemonSet = $.extensions.v1beta1.daemonSet,
  local toleration = $.core.v1.toleration,
  local volumeMount = $.core.v1.volumeMount,

  calicoNodeDaemonset:
    daemonSet.new("calico-node", [$.calicoNodeContainer, $.calicoInstallCNIContainer]) +
    daemonSet.mixin.spec.template.spec.withTolerations([
      toleration.new() +
      toleration.withKey("CriticalAddonsOnly") +
      toleration.withOperator("Exists"),

      toleration.new() +
      toleration.withKey("node-role.kubernetes.io/master") +
      toleration.withEffect("NoSchedule"),

      toleration.new() +
      toleration.withEffect("NoSchedule") +
      toleration.withOperator("Exists"),
    ]) +
    daemonSet.mixin.spec.template.spec.withHostNetwork(true) +
    daemonSet.mixin.spec.template.spec.withServiceAccountName("calico-node") +
    daemonSet.mixin.metadata.withAnnotations({ "scheduler.alpha.kubernetes.io/critical-pod": "" }) +
    $.util.hostVolumeMount("lib-modules", "/lib/modules", "/lib/modules", true) +
    $.util.hostVolumeMount("var-run-calico", "/var/run/calico", "/var/run/calico", false) +
    $.util.hostVolumeMount("var-lib-calico", "/var/lib/calico", "/var/lib/calico", false) +
    $.util.hostVolumeMount("xtables-lock", "/run/xtables.lock", "/run/xtables-lock", false) +
    $.util.hostVolumeMount("cni-bin-dir", "/opt/cni/bin", "/host/opt/cni/bin", false) +
    $.util.hostVolumeMount("cni-net-dir", "/etc/cni/net.d", "/host/etc/cni/net.d", false) +
    $.util.secretVolumeMount("calico", "/calico-secrets", 400),
}
