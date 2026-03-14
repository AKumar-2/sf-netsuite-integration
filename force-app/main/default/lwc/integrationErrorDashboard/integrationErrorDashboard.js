import { LightningElement, wire, track } from 'lwc';
import getFailedLogs from '@salesforce/apex/IntegrationDashboardController.getFailedLogs';
import retryLog from '@salesforce/apex/IntegrationDashboardController.retryLog';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

const actions = [
    { label: 'Retry', name: 'retry' }
];

const columns = [
    { label: 'Log Number', fieldName: 'Name', type: 'text' },
    { label: 'Target System', fieldName: 'Target_System__c', type: 'text' },
    { label: 'Object Type', fieldName: 'Object_Type__c', type: 'text' },
    { label: 'Status', fieldName: 'Status__c', type: 'text' },
    { label: 'Error Message', fieldName: 'Error_Message__c', type: 'text' },
    { label: 'Retry Count', fieldName: 'Retry_Count__c', type: 'number' },
    { label: 'SLA Breached', fieldName: 'SLA_Breached__c', type: 'boolean' },
    { label: 'Created Date', fieldName: 'CreatedDate', type: 'date' },
    {
        type: 'action',
        typeAttributes: { rowActions: actions },
    }
];

export default class IntegrationErrorDashboard extends LightningElement {
    @track logs;
    @track error;
    columns = columns;
    wiredLogsResult;

    @wire(getFailedLogs)
    wiredLogs(result) {
        this.wiredLogsResult = result;
        if (result.data) {
            this.logs = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error.body.message;
            this.logs = undefined;
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        if (actionName === 'retry') {
            this.retryIntegrationLog(row.Id);
        }
    }

    retryIntegrationLog(logId) {
        retryLog({ logId: logId })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Retry initiated successfully.',
                        variant: 'success',
                    }),
                );
                return refreshApex(this.wiredLogsResult);
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error retrying log',
                        message: error.body.message,
                        variant: 'error',
                    }),
                );
            });
    }
}
