{
  local policyRule = $.rbac.v1beta1.policyRule,

  weaveNetRBAC: $.util.rbac("weave-net", [
    policyRule.new() +
    policyRule.withApiGroups([""]) +
    policyRule.withResources(["pods", "namespaces", "nodes"]) +
    policyRule.withVerbs(["get", "list", "watch"]),

    policyRule.new() +
    policyRule.withApiGroups([""]) +
    policyRule.withResources(["nodes/status"]) +
    policyRule.withVerbs(["patch", "update"]),

    policyRule.new() +
    policyRule.withApiGroups(["networking.k8s.io"]) +
    policyRule.withResources(["networkpolicies"]) +
    policyRule.withVerbs(["get", "list", "watch"]),

    policyRule.new() +
    policyRule.withApiGroups([""]) +
    policyRule.withResources(["configmaps"]) +
    policyRule.withResourceNames(["weave-net"]) +
    policyRule.withVerbs(["get", "update"]),

    policyRule.new() +
    policyRule.withApiGroups([""]) +
    policyRule.withResources(["configmaps"]) +
    policyRule.withVerbs(["create"]),
  ]),

  local configMap = $.core.v1.configMap,

  weaveConfigMap:
    configMap.new("weave-net"),

  local container = $.core.v1.container,
  local envFrom = container.envFromType,

  weaveContainer::
    container.new("weave-net", $._images.weave) +
    container.withCommand(["/home/weave/launch.sh"]) +
    container.mixin.readinessProbe.httpGet.withPath("/status") +
    container.mixin.readinessProbe.httpGet.withPort(6784) +
    container.mixin.readinessProbe.httpGet.withScheme("HTTP") +
    container.mixin.readinessProbe.httpGet.withHost("127.0.0.1") +
    container.mixin.resources.withRequests({ cpu: "10m" }) +
    container.mixin.securityContext.withPrivileged(true) +
    container.withEnvFrom(
      envFrom.new() +
      envFrom.mixin.configMapRef.withName("weave-net"),
    ),

  weaveNPCContainer::
    container.new("weave-npc", $._images.weaveNPC) +
    container.mixin.resources.withRequests({ cpu: "10m" }) +
    container.mixin.securityContext.withPrivileged(true),

  local daemonSet = $.extensions.v1beta1.daemonSet,
  local toleration = $.core.v1.toleration,
  local volumeMount = $.core.v1.volumeMount,

  weaveNetDaemonSet:
    daemonSet.new("weave-net", [$.weaveContainer, $.weaveNPCContainer]) +
    daemonSet.mixin.spec.template.spec.withTolerations([
      toleration.new() +
      toleration.withOperator("Exists"),
    ]) +
    daemonSet.mixin.spec.template.spec.withHostNetwork(true) +
    daemonSet.mixin.spec.template.spec.withHostPid(true) +
    daemonSet.mixin.spec.template.spec.withServiceAccountName("weave-net") +
    daemonSet.mixin.metadata.withAnnotations({ "scheduler.alpha.kubernetes.io/critical-pod": "" }) +
    $.util.hostVolumeMount("weavedb", "/var/lib/weave", "/weavedb", false) +
    $.util.hostVolumeMount("xtables-lock", "/run/xtables.lock", "/run/xtables-lock", false) +
    $.util.hostVolumeMount("cni-bin-dir", $._config.cniBinDir, "/host/opt/cni/bin", false) +
    $.util.hostVolumeMount("cni-net-dir", $._config.cniNetDir, "/host/etc/cni/net.d", false) +
    $.util.hostVolumeMount("lib-modules", "/lib/modules", "/lib/modules", false) +
    $.util.hostVolumeMount("dbus", "/var/lib/dbus", "/host/var/lib/dbus", false),
}
