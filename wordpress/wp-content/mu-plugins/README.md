# Must-use plugins

Files here load automatically on every request — no activation, no deactivation.
Use them for code that must not be switched off (security hardening, environment
guards), not for shop features: those belong in `wp-content/plugins/hemp-core`.

This folder is version-controlled; put one file per concern (`00-env.php`,
`10-hardening.php`, …) or a folder with a loader.
