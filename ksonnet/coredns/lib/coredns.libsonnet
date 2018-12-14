{
  local clusterRole = $.rbac.v1beta1.clusterRole,
  local clusterRoleBinding = $.rbac.v1beta1.clusterRoleBinding,
  local policyRule = $.rbac.v1beta1.policyRule,
  local subject = $.rbac.v1beta1.subject,
  local serviceAccount = $.core.v1.serviceAccount,

  corednsServiceAccount:
    serviceAccount.new("coredns"),

  corednsClusterRole:
    clusterRole.new() +
    clusterRole.mixin.metadata.withName("system:coredns") +
    clusterRole.withRules([
      policyRule.new() +
      policyRule.withApiGroups([""]) +
      policyRule.withResources(["endpoints", "services", "pods", "namespaces"]) +
      policyRule.withVerbs(["list", "watch"]),

      policyRule.new() +
      policyRule.withApiGroups([""]) +
      policyRule.withResources(["nodes"]) +
      policyRule.withVerbs(["get"]),
    ]),

  corednsClusterRoleBinding:
    clusterRoleBinding.new() +
    clusterRoleBinding.mixin.metadata.withName("system:coredns") +
    clusterRoleBinding.mixin.roleRef.withApiGroup("rbac.authorization.k8s.io") +
    clusterRoleBinding.mixin.roleRef.withKind("ClusterRole") +
    clusterRoleBinding.mixin.roleRef.withName("system:coredns") +
    clusterRoleBinding.withSubjects([
      subject.new() +
      subject.withKind("ServiceAccount") +
      subject.withName("coredns") +
      subject.withNamespace($._config.namespace),
    ]),

  corednsConfig:: {
    Corefile: |||
      .:53 {
        errors
        health
        kubernetes %(clusterDomain)s in-addr.arpa ip6.arpa {
          pods insecure
          upstream
          fallthrough in-addr.arpa ip6.arpa
        }
        prometheus :9153
        proxy . %(upstream)s
        cache 30
        loop
        reload
        loadbalance
      }
    ||| % $._config,
  },

  local configMap = $.core.v1.configMap,

  corednsConfigMap:
    configMap.new("coredns") +
    configMap.withData($.corednsConfig),

  local container = $.core.v1.container,

  corednsContainer::
    container.new("coredns", $._images.coredns) +
    container.withPortsMixin([
      $.core.v1.containerPort.newUDP("dns", 53),
      $.core.v1.containerPort.new("dns-tcp", 53),
      $.core.v1.containerPort.new("coredns-metrics", 9153),
    ]) +
    container.withArgs([
      "-conf",
      "/etc/coredns/Corefile",
    ]) +
    $.util.resourcesRequests("100m", "70Mi") +
    $.util.resourcesLimits("100m", "170Mi") +
    container.mixin.livenessProbe.httpGet.withPath("/health") +
    container.mixin.livenessProbe.httpGet.withPort(8080) +
    container.mixin.livenessProbe.httpGet.withScheme("HTTP") +
    container.mixin.livenessProbe.withFailureThreshold(5) +
    container.mixin.livenessProbe.withInitialDelaySeconds(60) +
    container.mixin.livenessProbe.withSuccessThreshold(1) +
    container.mixin.livenessProbe.withTimeoutSeconds(5) +
    container.mixin.securityContext.withReadOnlyRootFilesystem(true) +
    container.mixin.securityContext.withAllowPrivilegeEscalation(false) +
    container.mixin.securityContext.capabilities.withAdd(["NET_BIND_SERVICE"]) +
    container.mixin.securityContext.capabilities.withDrop(["all"]),

  local deployment = $.apps.v1beta1.deployment,
  local toleration = $.core.v1.toleration,

  corednsDeployment:
    deployment.new("coredns", $._config.replicas, [$.corednsContainer]) +
    $.util.configVolumeMount("coredns", "/etc/coredns") +
    deployment.mixin.spec.template.spec.withServiceAccountName("coredns") +
    deployment.mixin.spec.template.metadata.withLabels({
      name: "coredns",
      "k8s-app": "kube-dns",
      "kubernetes.io/name": "CoreDNS",
    }) +
    deployment.mixin.spec.template.spec.withTolerations(
      toleration.new() +
      toleration.withKey("CriticalAddonsOnly") +
      toleration.withOperator("Exists"),
    ),

  local service = $.core.v1.service,
  local servicePort = $.core.v1.service.mixin.spec.portsType,

  corednsService:
    local ports = [
      servicePort.newNamed(c.name + "-" + port.name, port.containerPort, port.containerPort) +
      if std.objectHas(port, "protocol")
      then servicePort.withProtocol(port.protocol)
      else {}
      for c in $.corednsDeployment.spec.template.spec.containers
      for port in (c + container.withPortsMixin([])).ports
    ];
    $.core.v1.service.new(
      "kube-dns",  // name
      $.corednsDeployment.spec.template.metadata.labels,  // selector
      ports,
    ) +
    service.mixin.spec.withClusterIp($._config.clusterIP) +
    service.mixin.metadata.withAnnotations({
      "prometheus.io/port": "9153",
      "prometheus.io/scrape": "true",
    }) +
    service.mixin.metadata.withLabels({
      "k8s-app": "kube-dns",
      "kubernetes.io/cluster-service": "true",
      "kubernetes.io/name": "CoreDNS",
    }),

}
