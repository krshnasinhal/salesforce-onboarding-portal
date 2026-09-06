/**
 * Handles side effects of Onboarding_Task__c DML:
 *  - after insert: flips the parent Employee to "In Progress" (Req 2a-i) and
 *    sends a "new task assigned" email to the task Owner (Req 4a).
 *  - after update: when a task is marked Completed, re-checks whether ALL of
 *    the Employee's tasks are Completed and, if so, flips Employee to
 *    "Onboarded" (Req 2a-ii).
 */
public with sharing class OnboardingTaskTriggerHandler {

    public static void handleAfterInsert(List<Onboarding_Task__c> newTasks) {
        Set<Id> employeeIds = new Set<Id>();
        for (Onboarding_Task__c t : newTasks) {
            employeeIds.add(t.Employee__c);
        }

        markEmployeesInProgress(employeeIds);
        OnboardingEmailService.sendTaskCreatedEmails(newTasks);
    }

    public static void handleAfterUpdate(List<Onboarding_Task__c> newTasks, Map<Id, Onboarding_Task__c> oldMap) {
        Set<Id> employeeIdsToCheck = new Set<Id>();
        for (Onboarding_Task__c t : newTasks) {
            Onboarding_Task__c oldTask = oldMap.get(t.Id);
            if (t.Status__c == 'Completed' && oldTask.Status__c != 'Completed') {
                employeeIdsToCheck.add(t.Employee__c);
            }
        }
        if (!employeeIdsToCheck.isEmpty()) {
            StatusRollupService.rollupEmployeeStatus(employeeIdsToCheck);
        }
    }

    private static void markEmployeesInProgress(Set<Id> employeeIds) {
        if (employeeIds.isEmpty()) {
            return;
        }
        List<Employee__c> employeesToUpdate = new List<Employee__c>();
        for (Employee__c emp : [
            SELECT Id, Status__c FROM Employee__c
            WHERE Id IN :employeeIds AND Status__c = 'Offer Accepted'
        ]) {
            emp.Status__c = 'In Progress';
            employeesToUpdate.add(emp);
        }
        if (!employeesToUpdate.isEmpty()) {
            update employeesToUpdate;
        }
    }
}
