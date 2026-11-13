/**
 * Handles side effects of Onboarding_Task__c DML (called from OnboardingTaskTrigger):
 *  - after insert: flips the parent Employee to "In Progress" (Req 2a-i) and
 *    emails the Employee's Manager about the new task (Req 4a).
 *  - after update: when a task is marked Completed, re-checks whether ALL of
 *    the Employee's tasks are Completed and, if so, flips Employee to
 *    "Onboarded" (Req 2a-ii).
 */
public with sharing class OnboardingTaskTriggerHandler {

    /**
     * After-insert handler. Moves each affected Employee from
     * "Offer Accepted" to "In Progress" and sends the new-task emails.
     *
     * @param newTasks Newly inserted Onboarding_Task__c records (Trigger.new)
     */
    public static void handleAfterInsert(List<Onboarding_Task__c> newTasks) {
        Set<Id> employeeIds = new Set<Id>();
        for (Onboarding_Task__c t : newTasks) {
            employeeIds.add(t.Employee__c);
        }

        markEmployeesInProgress(employeeIds);
        OnboardingEmailService.sendTaskCreatedEmails(newTasks);
    }

    /**
     * After-update handler. Collects Employees whose tasks were just changed
     * to Completed and asks StatusRollupService to re-check them. Edits that
     * don't complete a task are ignored.
     *
     * @param newTasks Updated Onboarding_Task__c records (Trigger.new)
     * @param oldMap   Previous versions of the same records (Trigger.oldMap)
     */
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

    /**
     * Sets Status to "In Progress" for the given Employees, but only those
     * still at "Offer Accepted", so Employees already in progress or onboarded
     * are not moved backwards.
     *
     * @param employeeIds Ids of Employees that just received tasks
     */
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
