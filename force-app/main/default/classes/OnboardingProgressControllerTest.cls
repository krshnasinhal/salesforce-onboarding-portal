/**
 * Unit tests for OnboardingProgressController.getProgress.
 */
@isTest
private class OnboardingProgressControllerTest {

    /**
     * With 1 of 3 tasks Completed, the controller returns 3 total tasks,
     * 1 completed and 33% complete.
     */
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

    /**
     * An Employee with no tasks returns 0 tasks and 0% complete
     * (no divide-by-zero).
     */
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
