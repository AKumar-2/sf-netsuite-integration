# NetSuite Integration Framework for Salesforce

A reusable, configurable Apex integration framework to synchronize data (Products, Orders, Invoices, etc.) between Salesforce and NetSuite. This framework includes a custom LWC Error Dashboard for monitoring failed records, checking retry statuses, viewing SLA breaches, and initiating manual retries.

## Architecture

This integration leverages the following Salesforce platform capabilities:
- **REST APIs (Callouts):** Core mechanism for pushing data to NetSuite.
- **Named Credentials:** Used to securely store endpoint and authentication details for NetSuite.
- **Platform Events (`Integration_Event__e`):** Decouples Salesforce transactions from callouts, providing an asynchronous, scalable, and resilient architecture.
- **Batch Apex (`IntegrationRetryBatch`):** A scheduled batch job that finds failed integration logs and automatically attempts retries (up to a configured maximum limit).
- **Custom Objects (`Integration_Log__c`):** Serves as a persistent store for recording payload, status, error messages, and retry counts.
- **Lightning Web Components (LWC):** A user-friendly error dashboard (`integrationErrorDashboard`) for admins to monitor failing records and perform manual retries.

## Prerequisites

- Salesforce Developer/Sandbox org.
- Salesforce CLI (SFDX) installed.
- NetSuite Sandbox/Production instance with REST Web Services enabled and appropriate integrations (OAuth 2.0 or Token-Based Authentication) configured.

## Setup Instructions

1. **Deploy Metadata:**
   Use the Salesforce CLI to deploy the metadata to your org:
   ```bash
   sf project deploy start
   ```

2. **Configure Named Credential:**
   - Navigate to **Setup > Named Credentials**.
   - Edit the placeholder `NetSuite API` Named Credential.
   - Configure the Auth Provider and relevant endpoint based on your NetSuite account setup.

3. **Assign Permissions:**
   - Assign the `Integration Framework Admin` Permission Set to users who need access to view logs, monitor the dashboard, and execute manual retries.

4. **Schedule the Retry Batch:**
   - Open Developer Console.
   - Run the following anonymous Apex to schedule the retry batch to run every hour:
     ```apex
     IntegrationScheduler scheduler = new IntegrationScheduler();
     String cronExp = '0 0 * * * ?'; // Runs every hour
     System.schedule('NetSuite Hourly Integration Retry', cronExp, scheduler);
     ```

## Usage

### Triggering an Integration Sync

To sync a record, you can publish an `Integration_Event__e`. For example, from an Apex trigger on an `Order`:

```apex
Integration_Event__e evt = new Integration_Event__e(
    Action__c = 'Sync',
    Object_Type__c = 'Order',
    Record_Id__c = order.Id,
    Payload__c = JSON.serialize(orderPayloadMap)
);
EventBus.publish(evt);
```

### Monitoring Errors

- Navigate to the **Integration Framework** app using the App Launcher.
- Click on the **Integration Dashboard** tab.
- Review failed logs, SLA breaches, and click "Retry" to manually re-trigger a sync for a specific record.

## Testing

Run the included test class using SFDX:
```bash
sf apex run test --class-names IntegrationFrameworkTest --result-format human
```
