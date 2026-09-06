@isTest
private class OnboardingTaskGeneratorTest {

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
}
