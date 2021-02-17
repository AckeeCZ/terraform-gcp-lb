# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
