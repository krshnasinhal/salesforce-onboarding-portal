/**
 * Employee__c trigger. Delegates to OnboardingTaskGenerator to create
 * onboarding tasks when an Employee is inserted, and again when an
 * Employee's Department changes.
 */
trigger EmployeeTrigger on Employee__c (after insert, after update) {

    if (Trigger.isAfter && Trigger.isInsert) {
        // Requirement 1: auto-generate Onboarding Tasks from the matching
        // template whenever a new Employee is created with a Department.
        OnboardingTaskGenerator.generateTasksForEmployees(Trigger.new);
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        // If an Employee's Department is changed after creation
        // (e.g. HR corrected a mistake), generate tasks for the NEW department.
        // Only Employees whose Department actually changed are passed through,
        // so unrelated field edits don't trigger task generation.
        List<Employee__c> departmentChanged = new List<Employee__c>();
        for (Employee__c emp : Trigger.new) {
            Employee__c oldEmp = Trigger.oldMap.get(emp.Id);
            if (emp.Department__c != oldEmp.Department__c) {
                departmentChanged.add(emp);
            }
        }
        if (!departmentChanged.isEmpty()) {
            OnboardingTaskGenerator.generateTasksForEmployees(departmentChanged);
        }
    }
}