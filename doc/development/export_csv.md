---
stage: Manage
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Export to CSV

This document lists the different implementations of CSV export in GitLab codebase.

| Export type | How it works | Advantages | Disadvantages | Existing examples |
|---|---|---|---|---|
| Streaming | - Query and yield data in batches to a response stream.<br>- Download starts immediately. | - Report available immediately. | - No progress indicator.<br>- Requires a reliable connection. | [Export Audit Event Log](../administration/audit_events.md#export-to-csv) |
| Downloading | - Query and write data in batches to a temporary file.<br>- Loads the file into memory.<br>- Sends the file to the client. | - Report available immediately. | - Large amount of data might cause request timeout.<br>- Memory intensive.<br>- Request expires when user navigates to a different page. | [Export Chain of Custody Report](../user/compliance/compliance_report/#chain-of-custody-report) |
| As email attachment | - Asynchronously process the query with background job.<br>- Email uses the export as an attachment. | - Asynchronous processing. | - Requires users use a different app (email) to download the CSV.<br>- Email providers may limit attachment size. | - [Export Issues](../user/project/issues/csv_export.md)<br>- [Export Merge Requests](../user/project/merge_requests/csv_export.md) |
| As downloadable link in email (*) | - Asynchronously process the query with background job.<br>- Email uses an export link. | - Asynchronous processing.<br>- Bypasses email provider attachment size limit. | - Requires users use a different app (email).<br>- Requires additional storage and cleanup. | [Export User Permissions](https://gitlab.com/gitlab-org/gitlab/-/issues/1772) |
| Polling (non-persistent state) | - Asynchronously processes the query with the background job.<br>- Frontend(FE) polls every few seconds to check if CSV file is ready. | - Asynchronous processing.<br>- Automatically downloads to local machine on completion.<br>- In-app solution. | - Non-persistable request - request expires when user navigates to a different page.<br>- API is processed for each polling request. | [Export Vulnerabilities](../user/application_security/vulnerability_report/#export-vulnerability-details) |
| Polling (persistent state) (*) | - Asynchronously processes the query with background job.<br>- Backend (BE) maintains the export state<br>- FE polls every few seconds to check status.<br>- FE shows 'Download link' when export is ready.<br>- User can download or regenerate a new report. | - Asynchronous processing.<br>- No database calls made during the polling requests (HTTP 304 status is returned until export status changes).<br>- Does not require user to stay on page until export is complete.<br>- In-app solution.<br>- Can be expanded into a generic CSV feature (such as dashboard / CSV API). | - Requires to maintain export states in DB.<br>- Does not automatically download the CSV export to local machine, requires users to click 'Download' button. | [Export Merge Commits Report](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/43055) |

NOTE:
Export types marked as * are currently work in progress.
