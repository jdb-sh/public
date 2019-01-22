{
  local container = $.core.v1.container,

  s3_container::
    container.new("s3", $._images.s3) +
    container.withPortsMixin([
      $.core.v1.containerPort.new("s3", 4659),
    ]),

  local deployment = $.apps.v1beta1.deployment,

  s3_deployment:
    deployment.new("s3", 1, [$.s3_container]),

  s3_service:
    $.util.serviceFor($.s3_deployment),
}
