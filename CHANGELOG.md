# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v7.2.0] - 2025-12-15
### Added
- Support prefix path matching in `url_map`via `name_prefix` for path name.
- Validation to ensure only one of `name` or `name_prefix` is set per path.

## [v7.1.3] - 2025-11-27
### Fixed
- routing rules ordering by zero-padding priority keys so priorities are compared numerically rather than lexicographically.

## [v7.1.2] - 2025-08-18
### Added
- add `custom_self_signed_forwarding_rule_name`, `custom_target_https_proxy_name`, `self_signed_certificate_name`, `self_signed_tls` for easy migrations of https target proxies with self-signed certificates.
- add `self_signed_ssl_policy` to allow setting a custom SSL policy

## [v7.1.1] - 2025-03-25
### Fixed
- inconsistent conditional result types error when `route_rules` are not specified

## [v7.1.0] - 2025-03-18
### Added
- add support for route rules with url rewrite and url matching by query parameters

## [v7.0.0] - 2024-12-07
### Changed
- Make compatible with Google providers v6

## [v6.0.0] - 2022-08-21
### Added
- support for paths
- random suffix size to easy migrations
- add `custom_url_map_name`, `custom_target_http_proxy_custom_url_map_name`, `use_random_suffix_for_network_endpoint_group`, `global_forwarding_rule_name` to easy migrations
### Changed
- `url_map` is now handled with matchers instead of each service separately
- inputs for map are in services variable listing all the buckets, negs and cloud run services
### Removed
- negs, services and buckets as variables, instead keeping simple map variable

## [v5.1.0] - 2022-08-21
### Added
- support for HTTPS type of backend

## [v5.0.1] - 2022-08-19
### Fixed
- wrong zone to neg listing

## [v5.0.0] - 2022-08-12
### Added
- support for maps of negs, Cloud Run services and GCS buckets

## [v4.0.1] - 2022-08-03
### Added
- ignore of subject parameter of `tls_self_signed_cert` resource, allowing to upgrade `tls` provider to version 4 without having to regenerate certificate

## [v4.0.0] - 2022-08-01
### Removed
- `key_algorithm` parameter from `tls_self_signed_cert` resource

## [v3.8.0] - 2022-05-13
### Added
- Masking of `/metrics` endpoint

## [v3.7.0] - 2021-12-17
### Added
- Parameter `create_logging_sink_bucket` and accompanying `logging_sink_bucket_retency`

## [v3.6.0] - 2021-11-08
### Added
- Parameter `log_config_sample_rate`
### Changed
- `example` folder contents updated to Terraform 0.15+ format

## [v3.5.0] - 2021-07-27
### Added
- Add custom health check ports into firewall allow rule

## [v3.4.0] - 2021-07-20
### Added
- Support for externally signed TLS certs

## [v3.3.0] - 2021-04-15
### Added
- Turned on backend logging

## [v3.2.1] - 2021-03-18
### Fixed
- Default value for `health_check_request_path` should be `/healthz`

## [v3.2.0] - 2021-03-18
### Added
- Parameter to set health check path (URN)

## [v3.1.0] - 2021-03-03
### Added
- Add health check settings

## [v3.0.0] - 2021-02-24
### Changed
- Backend name to include `name` of the service (used in monitoring)

## [v2.0.0] - 2021-02-16
### Changed
- New parameter `hostnames` was introduced in favor of parameter `hostname`, it is list of strings with domain names pointing to our backend

## [v1.3.1] - 2021-02-16
### Fixed
- Remove duplicite `google_compute_global_forwarding_rule` definition

## [v1.3.0] - 2021-02-16
### Added
- Parameter `allow_non_tls_frontend` which creates Load balancer frontend listening on port 80

## [v1.2.0] - 2021-02-14
### Added
- Parameter `managed_certificate_name` which can override default managed certificate name - useful when migrating from Ingress-provisioned
certificate - we can run `terraform import` on provisioned certificate and don't wait for new certificate to provision (which will cause downtime)

## [v1.1.0] - 2021-02-14
### Fixed
- Added Parameter `backend_bucket_location` defining location of backend bucket that is used when our load balancers receive request that 
does not have HTTP header Host mathching our domain in `hostname`. Previous usage of parameter `region` prevented from creating bucket when
we had only zonal load-balancer (e.g. europe-west3-c was invalid location for bucket)

## [v1.0.0] - 2021-02-10
### Added
- Add initial commit with POC, example, pre-commit hooks
