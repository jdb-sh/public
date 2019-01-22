{
  local container = $.core.v1.container,

  ruler_container::
    container.new("ruler", $._images.ruler) +
    container.withArgs([
      "-server.http-listen-port=80",
      "-ruler.configs.url=http://configs.%(namespace)s.svc:80" % $._config,
      "-ruler.alertmanager-url=http://alertmanager.%(namespace)s.svc:80/api/prom/alertmanager/" % $._config,
      "-distributor.replication-factor=1"] +
      $.util.mapToFlags($._config.common_args) +
      $.util.mapToFlags($._config.consul_args) +
      $.util.mapToFlags($._config.dynamodb_args) +
      $.util.mapToFlags($._config.memcached_args) +
      $.util.mapToFlags($._config.s3_args),
    ) +
    container.withPortsMixin([
      $.core.v1.containerPort.new("http", 80),
    ]),

  local deployment = $.apps.v1beta1.deployment,

  ruler_deployment:
    deployment.new("ruler", 1, [$.ruler_container]),

  ruler_service:
    $.util.serviceFor($.ruler_deployment),
}
