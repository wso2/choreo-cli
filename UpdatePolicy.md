# Chroeo CLI Update Policy

## Update Frequency
We plan to release updates for the CLI on a bi-weekly basis, additionally, we may release unscheduled updates to 
address critical security vulnerabilities or introduce major new functionality

## Notification Strategy
New updates will be announced through the following channels:
- **In-tool notifications**: A message will be displayed within the CLI upon launch if a new version is available
- **Release notes**: Detailed information about each update including bug fixes, new features and breaking changes, will be published on the public repository

## Update Delivery Method
Updates will be delivered through the following methods,

### Package Managers(Not Available at now):
If installed via package manager updates will be available through the standard update mechanism of the particular package manager

### Installer Script:
Simply running the installer script will install the latest version of the CLI

## Rollback policy
If you encounter any issues with a new update, you can downgrade to the previous version by using the following command

```
# mac OS and linux
curl -o- https://cli.choreo.dev/install.sh | bash -s <release tag>

# windows
$arg = "<release-tag>"; $script = iwr https://cli.choreo.dev/install.ps1 -useb; & ([scriptblock]::Create($script)) $arg
```

## Breaking Changes
Significant changes that may break existing workflows will be clearly documented in the update’s release notes. 
We encourage users to review the release notes before installing an update to be aware of any potential issues

## Versioning Scheme
We use a <major>.<minor>.<patch> versioning scheme. Major releases introduce significant new features or breaking 
changes. Minor releases address bugs and introduce minor improvements. Patch releases fix critical security 
vulnerabilities
