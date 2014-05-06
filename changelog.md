# Changelog

==1.1==

* Added LaunchAgent
* Altered all script paths to work with Agent
* Added registry/punchcard maintenance
* Altered initial setup to test for internet connection
* Broke off setup script into first-run

* Refactored code for easier extension
* Changed Cron timing for more accuracy
* Changed runtime checking for more accuracy
* Changed log phrasing
* Added ability to view log easily from workflow (quicklook)
* Made arguments more granular
* Added External Trigger for adding cron job
* Added External Trigger for script filter
* Added External Trigger for script action
* Altered daemon control to give precedence to launchctl
* Fixed infinite loop on startup
* Added notifications for installation and error reporting
* Added invocation of cron after installation

==1.0==

* Initial Release
