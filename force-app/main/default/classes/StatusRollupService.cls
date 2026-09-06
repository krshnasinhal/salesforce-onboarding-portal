/**
 * Rolls up Onboarding_Task__c completion onto the parent Employee__c.Status__c.
 * An Employee is flipped to "Onboarded" only when it has at least one task
 * and every one of its tasks is Completed.
 */
public with sharing class StatusRollupService {

    public static void rollupEmployeeStatus(Set<Id> employeeIds) {
        if (employeeIds.isEmpty()) {
            return;
        }

        Map<Id, List<Onboarding_Task__c>> tasksByEmployee = new Map<Id, List<Onboarding_Task__c>>();
        for (Onboarding_Task__c t : [
            SELECT Id, Status__c, Employee__c
            FROM Onboarding_Task__c
            WHERE Employee__c IN :employeeIds
        ]) {
            if (!tasksByEmployee.containsKey(t.Employee__c)) {
                tasksByEmployee.put(t.Employee__c, new List<Onboarding_Task__c>());
            }
            tasksByEmployee.get(t.Employee__c).add(t);
        }

        List<Employee__c> employeesToUpdate = new List<Employee__c>();
        for (Employee__c emp : [
            SELECT Id, Status__c, Onboarded_Date__c FROM Employee__c WHERE Id IN :employeeIds
        ]) {
            List<Onboarding_Task__c> tasks = tasksByEmployee.get(emp.Id);
            if (tasks == null || tasks.isEmpty()) {
                continue;
            }
            Boolean allCompleted = true;
            for (Onboarding_Task__c t : tasks) {
                if (t.Status__c != 'Completed') {
                    allCompleted = false;
                    break;
                }
            }
            if (allCompleted && emp.Status__c != 'Onboarded') {
                emp.Status__c = 'Onboarded';
                emp.Onboarded_Date__c = Date.today();
                employeesToUpdate.add(emp);
            }
        }

        if (!employeesToUpdate.isEmpty()) {
            update employeesToUpdate;
        }
    }
}