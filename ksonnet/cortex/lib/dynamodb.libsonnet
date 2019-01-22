{
  local container = $.core.v1.container,

  dynamodb_container::
    container.new("dynamodb", $._images.dynamodb) +
    container.withPortsMixin([
      $.core.v1.containerPort.new("http", 8000),
    ]),

  local deployment = $.apps.v1beta1.deployment,

  dynamodb_deployment:
    deployment.new("dynamodb", 1, [$.dynamodb_container]),

  dynamodb_service:
    $.util.serviceFor($.dynamodb_deployment),
}
