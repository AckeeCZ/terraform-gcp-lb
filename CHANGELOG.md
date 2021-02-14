# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
