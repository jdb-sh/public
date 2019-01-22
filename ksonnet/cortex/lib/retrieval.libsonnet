{
  local policyRule = $.rbac.v1beta1.policyRule,

  retrieval_rbac:
    $.util.rbac("retrieval", [
      policyRule.new() +
      policyRule.withApiGroups(['']) +
      policyRule.withResources(['nodes', 'nodes/proxy', 'services', 'endpoints', 'pods']) +
      policyRule.withVerbs(['get', 'list', 'watch']),

      policyRule.new() +
      policyRule.withNonResourceUrls('/metrics') +
      policyRule.withVerbs(['get']),
  ]),

  local container = $.core.v1.container,

  retrieval_container::
    container.new("retrieval", $._images.prometheus) +
    container.withArgs([
      "--config.file=/etc/prometheus/prometheus.yml",
      "--web.listen-address=:80"] +
      $.util.mapToFlags($._config.common_args)
    ) +
    container.withPortsMixin([
      $.core.v1.containerPort.new("http-metrics", 80),
    ]),

  retrieval_watch_container::
    container.new('watch', $._images.watch) +
    container.withArgs([
      '-v',
      '-t',
      '-p=/etc/prometheus',
      'curl',
      '-X',
      'POST',
      '--fail',
      '-o',
      '-',
      '-sS',
      'http://localhost:80/-/reload',
    ]),

  local deployment = $.apps.v1beta1.deployment,

  retrieval_deployment:
    deployment.new("retrieval", 1, [$.retrieval_container, $.retrieval_watch_container]) +
    deployment.mixin.spec.template.spec.withServiceAccount('retrieval') +
    $.util.configVolumeMount("retrieval-config", "/etc/prometheus"),

  retrieval_service:
    $.util.serviceFor($.retrieval_deployment),

  local configMap = $.core.v1.configMap,

  prometheus_config_map:
    configMap.new('retrieval-config') +
    configMap.withData({
      'prometheus.yml': (importstr "prometheus.yml"),
    }),
}
