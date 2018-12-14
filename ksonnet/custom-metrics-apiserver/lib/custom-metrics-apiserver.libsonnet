{
  customMetricsAPIServerAPIService: {
    apiVersion: "apiregistration.k8s.io/v1beta1",
    kind: "APIService",
    metadata: {
      name: "v1beta1.custom.metrics.k8s.io",
    },
    spec: {
      insecureSkipTLSVerify: true,
      group: "custom.metrics.k8s.io",
      version: "v1beta1",
      groupPriorityMinimum: 1000,
      versionPriority: 10,
      service: {
        name: $._config.name,
        namespace: $._config.namespace,
      },
    },
  },

  local serviceAccount = $.core.v1.serviceAccount,

  customMetricsAPIServerServiceAccount:
    serviceAccount.new($._config.name) +
    serviceAccount.mixin.metadata.withNamespace($._config.namespace),

  local clusterRole = $.rbac.v1beta1.clusterRole,
  local policyRule = clusterRole.rulesType,

  customMetricsAPIServerClusterRole:
    clusterRole.new() +
    clusterRole.mixin.metadata.withName($._config.name) +
    clusterRole.withRules([
      policyRule.new() +
      policyRule.withApiGroups([""]) +
      policyRule.withResources(["nodes", "namespaces", "pods", "services"]) +
      policyRule.withVerbs(["get", "list", "watch"]),
    ]),

  local clusterRoleBinding = $.rbac.v1beta1.clusterRoleBinding,

  customMetricsAPIServerClusterRoleBinding:
    clusterRoleBinding.new() +
    clusterRoleBinding.mixin.metadata.withName($._config.name) +
    clusterRoleBinding.mixin.metadata.withNamespace($._config.namespace) +
    clusterRoleBinding.mixin.roleRef.withApiGroup("rbac.authorization.k8s.io") +
    clusterRoleBinding.mixin.roleRef.withName($._config.name) +
    clusterRoleBinding.mixin.roleRef.mixinInstance({ kind: "ClusterRole" }) +
    clusterRoleBinding.withSubjects([{
      kind: "ServiceAccount",
      name: $._config.name,
      namespace: $._config.namespace,
    }]),

  delegatorClusterRoleBinding:
    clusterRoleBinding.new() +
    clusterRoleBinding.mixin.metadata.withName("resource-metrics:system:auth-delegator") +
    clusterRoleBinding.mixin.roleRef.withApiGroup("rbac.authorization.k8s.io") +
    clusterRoleBinding.mixin.roleRef.withName("system:auth-delegator") +
    clusterRoleBinding.mixin.roleRef.mixinInstance({ kind: "ClusterRole" }) +
    clusterRoleBinding.withSubjects([{
      kind: "ServiceAccount",
      name: $._config.name,
      namespace: $._config.namespace,
    }]),

  serverResourcesClusterRole:
    clusterRole.new() +
    clusterRole.mixin.metadata.withName("resource-metrics-server-resources") +
    clusterRole.withRules([
      policyRule.new() +
      policyRule.withApiGroups(["metrics.k8s.io"]) +
      policyRule.withResources(["*"]) +
      policyRule.withVerbs(["*"]),
    ]),

  local roleBinding = $.rbac.v1beta1.roleBinding,

  authReaderRoleBinding:
    roleBinding.new() +
    roleBinding.mixin.metadata.withName("resource-metrics-auth-reader") +
    roleBinding.mixin.metadata.withNamespace("kube-system") +
    roleBinding.mixin.roleRef.withApiGroup("rbac.authorization.k8s.io") +
    roleBinding.mixin.roleRef.withName("extension-apiserver-authentication-reader") +
    roleBinding.mixin.roleRef.mixinInstance({ kind: "Role" }) +
    roleBinding.withSubjects([{
      kind: "ServiceAccount",
      name: $._config.name,
      namespace: $._config.namespace,
    }]),

  customMetricsAPIServerConfig:: {
    "config.yml": |||
      rules:
      - seriesQuery: "http_requests_total"
        resources:
          overrides:
            namespace: {resource: "namespace"}
            instance: {resource: "pod"}
        name:
          matches: "^(.*)_total"
          as: "${1}_per_second"
        metricsQuery: "sum(rate(<<.Series>>{<<.LabelMatchers>>}[2m])) by (<<.GroupBy>>)"
      - seriesQuery: "{__name__=~"^container_.*",container_name!="POD",namespace!="",instance!=""}"
        seriesFilters: []
        resources:
          overrides:
            namespace:
              resource: namespace
            instance:
              resource: pod
        name:
          matches: ^container_(.*)_seconds_total$
          as: ""
        metricsQuery: sum(rate(<<.Series>>{<<.LabelMatchers>>,container_name!="POD"}[1m])) by (<<.GroupBy>>)
      - seriesQuery: "{__name__=~"^container_.*",container_name!="POD",namespace!="",instance!=""}"
        seriesFilters:
        - isNot: ^container_.*_seconds_total$
        resources:
          overrides:
            namespace:
              resource: namespace
            instance:
              resource: pod
        name:
          matches: ^container_(.*)_total$
          as: ""
        metricsQuery: sum(rate(<<.Series>>{<<.LabelMatchers>>,container_name!="POD"}[1m])) by (<<.GroupBy>>)
      - seriesQuery: "{__name__=~"^container_.*",container_name!="POD",namespace!="",instance!=""}"
        seriesFilters:
        - isNot: ^container_.*_total$
        resources:
          overrides:
            namespace:
              resource: namespace
            instance:
              resource: pod
        name:
          matches: ^container_(.*)$
          as: ""
        metricsQuery: sum(<<.Series>>{<<.LabelMatchers>>,container_name!="POD"}) by (<<.GroupBy>>)
      - seriesQuery: "{namespace!="",__name__!~"^container_.*"}"
        seriesFilters:
        - isNot: .*_total$
        resources:
          template: <<.Resource>>
        name:
          matches: ""
          as: ""
        metricsQuery: sum(<<.Series>>{<<.LabelMatchers>>}) by (<<.GroupBy>>)
      - seriesQuery: "{namespace!="",__name__!~"^container_.*"}"
        seriesFilters:
        - isNot: .*_seconds_total
        resources:
          template: <<.Resource>>
        name:
          matches: ^(.*)_total$
          as: ""
        metricsQuery: sum(rate(<<.Series>>{<<.LabelMatchers>>}[1m])) by (<<.GroupBy>>)
      - seriesQuery: "{namespace!="",__name__!~"^container_.*"}"
        seriesFilters: []
        resources:
          template: <<.Resource>>
        name:
          matches: ^(.*)_seconds_total$
          as: ""
        metricsQuery: sum(rate(<<.Series>>{<<.LabelMatchers>>}[1m])) by (<<.GroupBy>>)
      resourceRules:
        cpu:
          containerQuery: sum(rate(container_cpu_usage_seconds_total{<<.LabelMatchers>>}[1m])) by (<<.GroupBy>>)
          nodeQuery: sum(rate(container_cpu_usage_seconds_total{<<.LabelMatchers>>, id="/"}[1m])) by (<<.GroupBy>>)
          resources:
            overrides:
              node:
                resource: node
              namespace:
                resource: namespace
              instance:
                resource: pod
          containerLabel: container_name
        memory:
          containerQuery: sum(container_memory_working_set_bytes{<<.LabelMatchers>>}) by (<<.GroupBy>>)
          nodeQuery: sum(container_memory_working_set_bytes{<<.LabelMatchers>>,id="/"}) by (<<.GroupBy>>)
          resources:
            overrides:
              node:
                resource: node
              namespace:
                resource: namespace
              instance:
                resource: pod
          containerLabel: container_name
        window: 1m
    |||,
  },

  local configMap = $.core.v1.configMap,

  customMetricsAPIServerConfigMap:
    configMap.new("custom-metrics-apiserver-config") +
    configMap.withData($.customMetricsAPIServerConfig),

  local container = $.core.v1.container,
  // TODO: Manage certificates rather than running insecurely
  customMetricsAPIServerContainer::
    container.new($._config.name, $._images.k8sPrometheusAdapter) +
    container.withPorts($.core.v1.containerPort.new("https", 443)) +
    container.withArgs([
      "/adapter",
      "--config=/etc/adapter/config.yml",
      "--secure-port=443",
      "--logtostderr=true",
      "--prometheus-url=http://prometheus.%(namespace)s.svc/prometheus" % $._config,
      "--metrics-relist-interval=1m",
    ]) +
    $.util.resourcesRequests("50m", "40Mi") +
    $.util.resourcesLimits("100m", "80Mi"),

  local deployment = $.apps.v1beta1.deployment,

  customMetricsAPIServerDeployment:
    deployment.new($._config.name, 1, [$.customMetricsAPIServerContainer]) +
    $.util.configVolumeMount("custom-metrics-apiserver-config", "/etc/adapter") +
    deployment.mixin.spec.template.spec.withServiceAccount($._config.name) +
    deployment.mixin.spec.template.spec.securityContext.withRunAsUser(0),


  customMetricsAPIServerService:
    $.util.serviceFor($.customMetricsAPIServerDeployment),
}
