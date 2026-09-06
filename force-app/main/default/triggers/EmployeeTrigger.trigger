trigger EmployeeTrigger on Employee__c (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        // Requirement 1: auto-generate Onboarding Tasks from the matching template
        // whenever a new Employee is created with a Department.
        OnboardingTaskGenerator.generateTasksForEmployees(Trigger.new);
    }
}
