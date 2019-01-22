{
  local container = $.core.v1.container,

  configs_db_container::
    container.new("configs", $._images.postgres) +
    container.withEnv({
      name: "POSTGRES_DB",
      value: "configs",
    }) +
    container.withPortsMixin([
      $.core.v1.containerPort.new("postgres", 5432)
    ]),

  local deployment = $.apps.v1beta1.deployment,

  configs_db_deployment:
    deployment.new("configs-db", 1, [$.configs_db_container]),

  configs_db_service:
    $.util.serviceFor($.configs_db_deployment),
}
