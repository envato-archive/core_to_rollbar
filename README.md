# core_to_rollbar
The app allows you to send a notification to the Rollbar service every time
some process on the host crashes.

The system requires configuration for this to work. First, the Rollbar token
needs to be stored in `/etc/core_to_rollbar.yml`:
```
access_token: "the_token"
environment: "production"
```

Next, the system needs to notify the application every time a program crashes.
This can be set up using the `core_pattern` sysctl:
```
sysctl 'kernel.core_pattern=/path/to/core_to_rollbar %p %u %h %s %t %E %c %P'
```

# Submitted attributes

This script submits:
- a message ("Process {path} [{pid}] ... crashed on signal 11 at ...")
- host (from `%h`)
- environment

# Apport

All events are forwarded to the local apport process with the default arguments
(`%p %t %s %P`), so that local crash reports will be generated as usual.

# Failures

Any failures are reported to syslog. In case this script fails completely, the
following message will be generated:
```
Core dump to |/path/to/core_to_rollbar pipe failed
```
