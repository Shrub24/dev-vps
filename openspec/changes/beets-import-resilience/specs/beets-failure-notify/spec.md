# Spec: Beets Failure Notification

## Purpose

Define ntfy.sh push notification behavior for failed Beets runner executions via systemd OnFailure template unit.

## ADDED Requirements

### Requirement: Failure notifications are delivered via ntfy.sh
The system SHALL send a push notification to a configured ntfy.sh topic when any beets runner service exits non-zero, using a systemd template unit wired via OnFailure.

#### Scenario: Runner fails and notification is configured
- **WHEN** a beets runner service exits non-zero
- **AND** ntfy.sh URL and authentication are configured
- **THEN** the OnFailure hook SHALL trigger `beets-notify-failure@<runner>.service`
- **AND** the notification SHALL include the runner name in the title
- **AND** the notification body SHALL include the last 20 journal lines for the failed runner

#### Scenario: Runner fails but notification is not configured
- **WHEN** a beets runner service exits non-zero
- **AND** ntfy.sh notification is disabled or URL is unset
- **THEN** the notify service SHALL either not be instantiated or exit cleanly as a no-op
- **AND** no external request SHALL be made

### Requirement: Notifications do not expose secrets in argv
The system SHALL NOT place ntfy.sh authentication tokens in the command arguments visible to the process table or journal.

#### Scenario: Token-based authentication is used
- **WHEN** a ntfy.sh token file path is configured
- **THEN** the curl Authorization header SHALL read the token from the file at runtime (e.g., via `--header "Authorization: Bearer $(cat $CREDENTIALS_DIRECTORY/token)"`)
- **AND** the token SHALL NOT appear in `ps` output or the systemd journal argv recording

#### Scenario: No token is configured
- **WHEN** no ntfy.sh token file is provided
- **THEN** the notification SHALL be sent to a public/unauthenticated topic URL
- **AND** no token file SHALL be referenced

### Requirement: Notification template unit works for all runner kinds
The system SHALL use a single `beets-notify-failure@.service` systemd template unit for all runner kinds. The `%i` instance specifier SHALL be used to identify the failed runner.

#### Scenario: Import runner fails
- **WHEN** `beets-inbox.service` exits non-zero
- **THEN** `beets-notify-failure@beets-inbox.service` SHALL be started
- **AND** the notification SHALL reference "beets-inbox" in its title

#### Scenario: Permission-reconcile runner fails
- **WHEN** `beets-permission-reconcile.service` exits non-zero
- **THEN** `beets-notify-failure@beets-permission-reconcile.service` SHALL be started
- **AND** the notification SHALL reference "beets-permission-reconcile" in its title
