{
  local container = $.core.v1.container,

  table_manager_container::
    container.new("table-manager", $._images.table_manager) +
    container.withArgs([
      "-server.http-listen-port=80"] +
      $.util.mapToFlags($._config.common_args) +
      $.util.mapToFlags($._config.dynamodb_args)
    ) +
    container.withPortsMixin([
      $.core.v1.containerPort.new("http", 80),
    ]),

  local deployment = $.apps.v1beta1.deployment,

  table_manager_deployment:
    deployment.new("table-manager", 1, [$.table_manager_container]),

  table_manager_service:
    $.util.serviceFor($.table_manager_deployment),
}
