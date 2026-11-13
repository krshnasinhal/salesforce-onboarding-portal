/**
 * Unit tests for OnboardingTaskGenerator and EmployeeTrigger: task generation
 * on insert, no-template handling, bulk inserts and department changes.
 */
@isTest
private class OnboardingTaskGeneratorTest {

    /**
     * Inserting an Employee creates one task per template task, with Due Date
     * = Joining Date + Days to Complete, and moves the Employee to In Progress.
     */
    @isTest
    static void testTasksGeneratedFromTemplate() {
        OnboardingTestDataFactory.createTemplateWithTasks('Engineering');
        Date joinDate = Date.today().addDays(14);

        Test.startTest();
        Employee__c emp = OnboardingTestDataFactory.buildEmployee('Engineering', joinDate);
        insert emp; // fires EmployeeTrigger -> OnboardingTaskGenerator
        Test.stopTest();

        List<Onboarding_Task__c> tasks = [
            SELECT Id, Name, Due_Date__c, Task_Type__c FROM Onboarding_Task__c
            WHERE Employee__c = :emp.Id
        ];
        System.assertEquals(3, tasks.size(), 'Expected 3 tasks cloned from the template');

        for (Onboarding_Task__c t : tasks) {
            if (t.Name == 'Provision Laptop') {
                System.assertEquals(joinDate.addDays(3), t.Due_Date__c);
            }
        }

        Employee__c updated = [SELECT Status__c FROM Employee__c WHERE Id = :emp.Id];
        System.assertEquals('In Progress', updated.Status__c, 'Status should flip once first task is created');
    }

    /**
     * An Employee whose Department has no template gets no tasks and keeps
     * the Offer Accepted status.
     */
    @isTest
    static void testNoMatchingTemplate_noTasksCreated() {
        Date joinDate = Date.today().addDays(7);

        Test.startTest();
        Employee__c emp = OnboardingTestDataFactory.buildEmployee('Marketing', joinDate);
        insert emp; // no template exists for Marketing
        Test.stopTest();

        List<Onboarding_Task__c> tasks = [SELECT Id FROM Onboarding_Task__c WHERE Employee__c = :emp.Id];
        System.assertEquals(0, tasks.size());

        Employee__c updated = [SELECT Status__c FROM Employee__c WHERE Id = :emp.Id];
        System.assertEquals('Offer Accepted', updated.Status__c, 'Status should not change with no tasks');
    }

    /**
     * Inserting 50 Employees in one transaction creates 150 tasks without
     * hitting governor limits (bulkification check).
     */
    @isTest
    static void testBulkInsert() {
        OnboardingTestDataFactory.createTemplateWithTasks('Sales');
        Date joinDate = Date.today().addDays(10);

        List<Employee__c> employees = new List<Employee__c>();
        for (Integer i = 0; i < 50; i++) {
            employees.add(OnboardingTestDataFactory.buildEmployee('Sales', joinDate));
        }

        Test.startTest();
        insert employees;
        Test.stopTest();

        List<Onboarding_Task__c> tasks = [SELECT Id FROM Onboarding_Task__c];
        System.assertEquals(150, tasks.size(), '50 employees x 3 template tasks each');
    }

    /**
     * Mentor point 3: when HR changes an Employee's Department after creation,
     * the new department's tasks are added, existing tasks are kept, and
     * switching back does not create duplicates.
     */
    @isTest
    static void testDepartmentChange_addsNewTasksWithoutDuplicates() {
        // Engineering template (3 tasks from the factory)
        OnboardingTestDataFactory.createTemplateWithTasks('Engineering');

        // Sales template: the factory likely reuses the same task names, so
        // rename the Sales template's tasks to make them distinct. We find them
        // as "the Template Tasks that didn't exist before this call".
        Set<Id> existingTemplateTaskIds = new Map<Id, Template_Task__c>(
            [SELECT Id FROM Template_Task__c]
        ).keySet();
        OnboardingTestDataFactory.createTemplateWithTasks('Sales');
        List<Template_Task__c> salesTemplateTasks = [
            SELECT Id, Name FROM Template_Task__c WHERE Id NOT IN :existingTemplateTaskIds
        ];
        for (Template_Task__c tt : salesTemplateTasks) {
            tt.Name = 'Sales - ' + tt.Name;
        }
        update salesTemplateTasks;

        // Employee created in Engineering -> 3 Engineering tasks
        Employee__c emp = OnboardingTestDataFactory.buildEmployee('Engineering', Date.today().addDays(14));
        insert emp;
        System.assertEquals(3, [SELECT COUNT() FROM Onboarding_Task__c WHERE Employee__c = :emp.Id],
            'Engineering tasks should be generated on insert');

        // HR corrects the department -> Sales tasks are added, Engineering tasks kept
        Test.startTest();
        emp.Department__c = 'Sales';
        update emp;
        Test.stopTest();

        System.assertEquals(3 + salesTemplateTasks.size(),
            [SELECT COUNT() FROM Onboarding_Task__c WHERE Employee__c = :emp.Id],
            'Department change should add the new department\'s tasks and keep existing ones');

        // Switching back must not duplicate the Engineering tasks
        emp.Department__c = 'Engineering';
        update emp;
        System.assertEquals(3 + salesTemplateTasks.size(),
            [SELECT COUNT() FROM Onboarding_Task__c WHERE Employee__c = :emp.Id],
            'Switching back should not create duplicate tasks');
    }
}