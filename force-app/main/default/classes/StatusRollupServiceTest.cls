@isTest
private class StatusRollupServiceTest {

    @isTest
    static void testEmployeeFlipsToOnboardedWhenAllTasksComplete() {
        OnboardingTestDataFactory.createTemplateWithTasks('Engineering');
        Employee__c emp = OnboardingTestDataFactory.buildEmployee('Engineering', Date.today());
        insert emp;

        List<Onboarding_Task__c> tasks = [SELECT Id, Status__c FROM Onboarding_Task__c WHERE Employee__c = :emp.Id];
        System.assertEquals(3, tasks.size());

        Test.startTest();
        for (Onboarding_Task__c t : tasks) {
            t.Status__c = 'Completed';
        }
        update tasks; // fires OnboardingTaskTrigger after update -> StatusRollupService
        Test.stopTest();

        Employee__c updated = [SELECT Status__c FROM Employee__c WHERE Id = :emp.Id];
        System.assertEquals('Onboarded', updated.Status__c);
    }

    @isTest
    static void testEmployeeStaysInProgressWhenPartiallyComplete() {
        OnboardingTestDataFactory.createTemplateWithTasks('Engineering');
        Employee__c emp = OnboardingTestDataFactory.buildEmployee('Engineering', Date.today());
        insert emp;

        List<Onboarding_Task__c> tasks = [SELECT Id, Status__c FROM Onboarding_Task__c WHERE Employee__c = :emp.Id];
        tasks[0].Status__c = 'Completed';

        Test.startTest();
        update tasks[0];
        Test.stopTest();

        Employee__c updated = [SELECT Status__c FROM Employee__c WHERE Id = :emp.Id];
        System.assertEquals('In Progress', updated.Status__c);
    }
}
