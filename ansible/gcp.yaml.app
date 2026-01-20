plugin: gcp_compute
projects:
  - app-practable-io-alpha
  - web-practable-io-alpha
auth_kind: serviceaccount
service_account_file: /home/tim/secret/app.practable.io/app-practable-io-alpha-84a62509ce73.json
keyed_groups:
  - key: labels
  - prefix: label
groups:
  development: "'environment' in (labels|list)"
  app_practable_dev: "'app-practable-io-alpha-dev' in name"
  app_practable_ed0: "name == 'app-practable-io-alpha-ed0'"
  app_practable_ed0_alternate: "name == 'app-practable-io-alpha-ed0-alternate'"
  app_practable_ed0-staging: "name == 'app-practable-io-alpha-ed0-staging'"
  app_practable_ed_dev_ui: "'app-practable-io-alpha-ed-dev-ui' in name"
  web_practable_default: "'web-practable-io-alpha-default' in name"
  app_practable_monitoring: "name == 'app-practable-io-alpha-monitoring'"
  app_practable_runner: "name == 'app-practable-io-alpha-runner'"

