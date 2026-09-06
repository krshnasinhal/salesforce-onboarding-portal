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
