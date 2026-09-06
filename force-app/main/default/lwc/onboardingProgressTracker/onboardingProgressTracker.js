import { LightningElement, api, wire } from 'lwc';
import getProgress from '@salesforce/apex/OnboardingProgressController.getProgress';

const TASK_TYPE_ORDER = ['HR', 'IT', 'Manager', 'Admin'];

export default class OnboardingProgressTracker extends LightningElement {
    @api recordId; // Employee__c Id, auto-populated on the record page

    progress;
    error;

    @wire(getProgress, { employeeId: '$recordId' })
    wiredProgress({ data, error }) {
        if (data) {
            this.progress = data;
            this.error = undefined;
        } else if (error) {
            this.error = this.reduceError(error);
            this.progress = undefined;
        }
    }

    get percentComplete() {
        return this.progress ? this.progress.percentComplete : 0;
    }

    get progressLabel() {
        if (!this.progress) return '';
        return `${this.progress.completedTasks} of ${this.progress.totalTasks} tasks complete`;
    }

    get hasTasks() {
        return this.progress && this.progress.totalTasks > 0;
    }

    get groupedTasks() {
        if (!this.progress || !this.progress.tasks) {
            return [];
        }
        const groups = {};
        for (const task of this.progress.tasks) {
            const type = task.Task_Type__c || 'Other';
            if (!groups[type]) {
                groups[type] = [];
            }
            groups[type].push({
                ...task,
                badgeClass: this.badgeClassForStatus(task.Status__c)
            });
        }
        const orderedTypes = [
            ...TASK_TYPE_ORDER.filter((t) => groups[t]),
            ...Object.keys(groups).filter((t) => !TASK_TYPE_ORDER.includes(t))
        ];
        return orderedTypes.map((type) => ({
            type,
            tasks: groups[type]
        }));
    }

    badgeClassForStatus(status) {
        switch (status) {
            case 'Completed':
                return 'slds-badge slds-theme_success';
            case 'In Progress':
                return 'slds-badge slds-theme_warning';
            default:
                return 'slds-badge';
        }
    }

    reduceError(error) {
        if (error && error.body && error.body.message) {
            return error.body.message;
        }
        return 'Unknown error loading onboarding progress.';
    }
}
