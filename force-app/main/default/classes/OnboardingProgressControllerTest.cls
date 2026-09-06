@isTest
private class OnboardingProgressControllerTest {

    @isTest
    static void testGetProgress_partiallyComplete() {
        OnboardingTestDataFactory.createTemplateWithTasks('Engineering');
        Employee__c emp = OnboardingTestDataFactory.buildEmployee('Engineering', Date.today());
        insert emp;

        List<Onboarding_Task__c> tasks = [SELECT Id FROM Onboarding_Task__c WHERE Employee__c = :emp.Id];
        tasks[0].Status__c = 'Completed';
        update tasks[0];

        Test.startTest();
        OnboardingProgressController.ProgressResult result = OnboardingProgressController.getProgress(emp.Id);
        Test.stopTest();

        System.assertEquals(3, result.totalTasks);
        System.assertEquals(1, result.completedTasks);
        System.assertEquals(33, result.percentComplete);
        System.assertEquals(3, result.tasks.size());
    }

    @isTest
    static void testGetProgress_noTasks() {
        Employee__c emp = OnboardingTestDataFactory.buildEmployee('Marketing', Date.today());
        insert emp; // no template -> no tasks generated

        Test.startTest();
        OnboardingProgressController.ProgressResult result = OnboardingProgressController.getProgress(emp.Id);
        Test.stopTest();

        System.assertEquals(0, result.totalTasks);
        System.assertEquals(0, result.percentComplete);
        System.assertEquals(0, result.tasks.size());
    }
}
