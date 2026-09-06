/**
 * Generates Onboarding_Task__c records for newly created Employee__c records
 * by matching each Employee's Department to an Onboarding_Template__c and
 * cloning its Template_Task__c children.
 *
 * Bulk-safe: handles any number of Employees in a single trigger invocation
 * with a fixed number of SOQL queries (no queries inside loops).
 */
public with sharing class OnboardingTaskGenerator {

    public static void generateTasksForEmployees(List<Employee__c> newEmployees) {
        // 1. Collect distinct departments from the incoming Employees.
        Set<String> departments = new Set<String>();
        for (Employee__c emp : newEmployees) {
            if (String.isNotBlank(emp.Department__c)) {
                departments.add(emp.Department__c);
            }
        }
        if (departments.isEmpty()) {
            return;
        }

        // 2. Query one matching Onboarding_Template__c per Department, with its
        //    Template_Task__c children, in a single query.
        Map<String, Onboarding_Template__c> templateByDepartment = new Map<String, Onboarding_Template__c>();
        for (Onboarding_Template__c tmpl : [
            SELECT Id, Department__c,
                   (SELECT Id, Name, Task_Type__c, Days_to_Complete__c FROM Template_Tasks__r)
            FROM Onboarding_Template__c
            WHERE Department__c IN :departments
        ]) {
            // If multiple templates exist for the same department, the first one found wins.
            if (!templateByDepartment.containsKey(tmpl.Department__c)) {
                templateByDepartment.put(tmpl.Department__c, tmpl);
            }
        }

        // 3. Build Onboarding_Task__c records for every Employee whose Department
        //    has a matching template.
        List<Onboarding_Task__c> tasksToInsert = new List<Onboarding_Task__c>();

        for (Employee__c emp : newEmployees) {
            Onboarding_Template__c tmpl = templateByDepartment.get(emp.Department__c);
            if (tmpl == null || tmpl.Template_Tasks__r == null || tmpl.Template_Tasks__r.isEmpty()) {
                continue; // no template configured for this department yet
            }
            if (emp.Joining_Date__c == null) {
                continue; // can't compute a Due Date without a Joining Date
            }

            for (Template_Task__c templateTask : tmpl.Template_Tasks__r) {
                Onboarding_Task__c newTask = new Onboarding_Task__c();
                newTask.Name = templateTask.Name;
                newTask.Task_Type__c = templateTask.Task_Type__c;
                newTask.Status__c = 'Not Started';
                newTask.Employee__c = emp.Id;
                Integer daysToComplete = templateTask.Days_to_Complete__c != null
                    ? Integer.valueOf(templateTask.Days_to_Complete__c) : 0;
                newTask.Due_Date__c = emp.Joining_Date__c.addDays(daysToComplete);
                tasksToInsert.add(newTask);
            }
        }

        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }
}
