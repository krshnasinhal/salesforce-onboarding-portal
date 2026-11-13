/**
 * Generates Onboarding_Task__c records for Employee__c records by matching
 * each Employee's Department to an Onboarding_Template__c and cloning its
 * Template_Task__c children.
 *
 * Runs on Employee insert and on a Department change (see EmployeeTrigger).
 *
 * Bulk-safe: handles any number of Employees in a single trigger invocation
 * with a fixed number of SOQL queries (no queries inside loops).
 *
 * Template selection: when a Department has more than one
 * template, only Active templates are considered and the highest Version__c
 * wins, so templates can evolve without breaking historical data.
 *
 * Duplicate guard: tasks are only created if the Employee
 * doesn't already have a task with that name, so changing an Employee's
 * Department adds the new department's tasks without duplicating existing ones.
 */
public with sharing class OnboardingTaskGenerator {

    /**
     * Entry point called by EmployeeTrigger. For each Employee with a
     * Department that has a matching active template, generates the
     * corresponding Onboarding_Task__c records (skipping any the Employee
     * already has) and inserts them.
     *
     * @param newEmployees Employee__c records from trigger context to process
     */
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

        // 2. Resolve one template per Department: Active only, highest Version__c first.
        Map<String, Onboarding_Template__c> templateByDepartment =
            new Map<String, Onboarding_Template__c>();
        for (Onboarding_Template__c tmpl : [
            SELECT Id, Department__c, Active__c, Version__c,
                   (SELECT Id, Name, Task_Type__c, Days_to_Complete__c FROM Template_Tasks__r)
            FROM Onboarding_Template__c
            WHERE Department__c IN :departments
              AND Active__c = true
            ORDER BY Version__c DESC NULLS LAST
        ]) {
            // First (highest active version) per Department wins.
            if (!templateByDepartment.containsKey(tmpl.Department__c)) {
                templateByDepartment.put(tmpl.Department__c, tmpl);
            }
        }

        // 3. Find task names each Employee already has, so a Department
        //    change doesn't recreate tasks they already have.
        Set<Id> employeeIds = new Set<Id>();
        for (Employee__c emp : newEmployees) {
            employeeIds.add(emp.Id);
        }
        Map<Id, Set<String>> existingTaskNamesByEmployee = new Map<Id, Set<String>>();
        for (Onboarding_Task__c existing : [
            SELECT Name, Employee__c
            FROM Onboarding_Task__c
            WHERE Employee__c IN :employeeIds
        ]) {
            if (!existingTaskNamesByEmployee.containsKey(existing.Employee__c)) {
                existingTaskNamesByEmployee.put(existing.Employee__c, new Set<String>());
            }
            existingTaskNamesByEmployee.get(existing.Employee__c).add(existing.Name);
        }

        // 4. Build tasks for each Employee whose Department has a template, skipping duplicates.
        List<Onboarding_Task__c> tasksToInsert = new List<Onboarding_Task__c>();

        for (Employee__c emp : newEmployees) {
            Onboarding_Template__c tmpl = templateByDepartment.get(emp.Department__c);
            if (tmpl == null || tmpl.Template_Tasks__r == null || tmpl.Template_Tasks__r.isEmpty()) {
                continue; // no active template for this department yet
            }
            if (emp.Joining_Date__c == null) {
                continue; // can't compute a Due Date without a Joining Date
            }

            Set<String> alreadyHas = existingTaskNamesByEmployee.containsKey(emp.Id)
                ? existingTaskNamesByEmployee.get(emp.Id)
                : new Set<String>();

            for (Template_Task__c templateTask : tmpl.Template_Tasks__r) {
                if (alreadyHas.contains(templateTask.Name)) {
                    continue; // already has this task, don't duplicate
                }
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