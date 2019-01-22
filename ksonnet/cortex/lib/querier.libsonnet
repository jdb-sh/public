{
  local container = $.core.v1.container,

  querier_container::
    container.new("querier", $._images.querier) +
    container.withArgs([
      "-server.http-listen-port=80",
      "-querier.frontend-address=query-frontend.%(namespace)s.svc:9095" % $._config,
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

  querier_deployment:
    deployment.new("querier", 1, [$.querier_container]),

  querier_service:
  $.util.serviceFor($.querier_deployment),
}
