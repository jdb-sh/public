{
  local container = $.core.v1.container,

  nginx_container::
    container.new("nginx", $._images.nginx) +
    container.withPortsMixin([
      $.core.v1.containerPort.new("http", 80),
    ]),

  local deployment = $.apps.v1beta1.deployment,

  nginx_deployment:
    deployment.new("nginx", 1, [$.nginx_container]) +
    $.util.configVolumeMount("nginx-config", "/etc/nginx"),

  nginx_service:
    $.util.serviceFor($.nginx_deployment),

  local configMap = $.core.v1.configMap,

  nginx_config_map:
    configMap.new("nginx-config") +
    configMap.withData({
      "nginx.conf": |||
        worker_processes  5;  ## Default: 1
        error_log  /dev/stderr;
        pid        /tmp/nginx.pid;
        worker_rlimit_nofile 8192;
        events {
          worker_connections  4096;  ## Default: 1024
        }
        http {
          default_type application/octet-stream;
          log_format   main '$remote_addr - $remote_user [$time_local]  $status '
            '"$request" $body_bytes_sent "$http_referer" '
            '"$http_user_agent" "$http_x_forwarded_for"';
          access_log   /dev/stderr  main;
          sendfile     on;
          tcp_nopush   on;
          resolver kube-dns.kube-system.svc;
          server { # simple reverse-proxy
            listen 80;
            proxy_set_header X-Scope-OrgID 0;
            # pass requests for dynamic content to rails/turbogears/zope, et al
            location = /api/prom/push {
              proxy_pass      http://distributor.%(namespace)s.svc.%(cluster_dns_suffix)s$request_uri;
            }
            location ~ /api/prom/.* {
              proxy_pass      http://query-frontend.%(namespace)s.svc.%(cluster_dns_suffix)s$request_uri;
            }
          }
        }
      ||| % $._config,
    }),
}
