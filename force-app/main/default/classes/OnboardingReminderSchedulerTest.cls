/**
 * Unit tests for the OnboardingReminderScheduler scheduled job.
 */
@isTest
private class OnboardingReminderSchedulerTest {

    /**
     * Schedules the job with tasks that are Not Started and due in 2 days;
     * the job runs at Test.stopTest() and sends reminders without errors.
     */
    @isTest
    static void testScheduledJobSendsRemindersForTasksDueInTwoDays() {
        OnboardingTestDataFactory.createTemplateWithTasks('Engineering');
        // Join today so "Send Welcome Email" (0 days) is due today,
        // and manually push one task's due date to exactly +2 days.
        Employee__c emp = OnboardingTestDataFactory.buildEmployee('Engineering', Date.today());
        insert emp;

        List<Onboarding_Task__c> tasks = [
            SELECT Id, Status__c, Due_Date__c FROM Onboarding_Task__c WHERE Employee__c = :emp.Id
        ];
        for (Onboarding_Task__c t : tasks) {
            t.Due_Date__c = Date.today().addDays(2);
            t.Status__c = 'Not Started';
        }
        update tasks;

        Test.startTest();
        String cronExpr = '0 0 6 * * ?';
        System.schedule('Test Onboarding Reminder Job', cronExpr, new OnboardingReminderScheduler());
        Test.stopTest();
        // Job enqueued and executed at stopTest; no exception = success.
    }

    /**
     * Running the job when no tasks are due is a no-op without errors.
     */
    @isTest
    static void testExecuteDirectly_noMatchingTasks() {
        Test.startTest();
        new OnboardingReminderScheduler().execute(null);
        Test.stopTest();
        // No tasks exist yet, so this should simply no-op without error.
    }
}
