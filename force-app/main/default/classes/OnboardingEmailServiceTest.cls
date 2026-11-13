/**
 * Unit tests for OnboardingEmailService: new-task emails, reminder emails
 * and the empty-list no-op path.
 */
@isTest
private class OnboardingEmailServiceTest {

    /**
     * Inserting an Employee generates tasks and runs the new-task email path
     * for a Manager who has an email address, without errors.
     */
    @isTest
    static void testSendTaskCreatedEmails_ownerHasEmail() {
        // The factory sets Manager__c to the running user, who has an email,
        // so this exercises the "Manager has an email" branch.
        OnboardingTestDataFactory.createTemplateWithTasks('Engineering');
        Employee__c emp = OnboardingTestDataFactory.buildEmployee('Engineering', Date.today());

        Test.startTest();
        insert emp; // fires trigger -> generator -> task insert -> sendTaskCreatedEmails
        Test.stopTest();

        List<Onboarding_Task__c> tasks = [SELECT Id FROM Onboarding_Task__c WHERE Employee__c = :emp.Id];
        System.assertEquals(3, tasks.size());
        // No exception thrown = email path executed cleanly under Test.isRunningTest() guard.
    }

    /**
     * Calls sendReminderEmails directly with tasks whose Manager fields are
     * populated, covering reminder email construction.
     */
    @isTest
    static void testSendReminderEmails_directCall() {
        OnboardingTestDataFactory.createTemplateWithTasks('Engineering');
        Employee__c emp = OnboardingTestDataFactory.buildEmployee('Engineering', Date.today());
        insert emp;

        List<Onboarding_Task__c> tasks = [
            SELECT Id, Name, Due_Date__c, Employee__r.Manager__r.Email, Employee__r.Manager__r.Name
            FROM Onboarding_Task__c
            WHERE Employee__c = :emp.Id
        ];

        Test.startTest();
        OnboardingEmailService.sendReminderEmails(tasks);
        Test.stopTest();
        // No exception thrown = success; SingleEmailMessage construction is covered.
    }

    /**
     * Both email methods return early without error when given an empty list.
     */
    @isTest
    static void testSendEmails_emptyListNoOp() {
        Test.startTest();
        OnboardingEmailService.sendTaskCreatedEmails(new List<Onboarding_Task__c>());
        OnboardingEmailService.sendReminderEmails(new List<Onboarding_Task__c>());
        Test.stopTest();
        // Both should return early without error.
    }
}
