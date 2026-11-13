/**
 * Onboarding_Task__c trigger. Contains no logic itself; delegates to
 * OnboardingTaskTriggerHandler (In Progress status, new-task emails, and
 * Onboarded roll-up when tasks are completed).
 */
trigger OnboardingTaskTrigger on Onboarding_Task__c (after insert, after update) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            OnboardingTaskTriggerHandler.handleAfterInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            OnboardingTaskTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
