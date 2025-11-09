global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'service-a'
    metrics_path: '/metrics'
    static_configs:
      - targets: ['${service_a_alb_dns}']