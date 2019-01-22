{
  local container = $.core.v1.container,

  distributor_container::
    container.new("distributor", $._images.distributor) +
    container.withArgs([
      "-server.http-listen-port=80",
      "-distributor.shard-by-all-labels",
      "-distributor.replication-factor=1"] +
      $.util.mapToFlags($._config.common_args) +
      $.util.mapToFlags($._config.consul_args),
    ) +
    container.withPortsMixin([
      $.core.v1.containerPort.new("http", 80)
    ]),

  local deployment = $.apps.v1beta1.deployment,

  distributor_deployment:
    deployment.new("distributor", 1, [$.distributor_container]),

  distributor_service:
    $.util.serviceFor($.distributor_deployment),
}
