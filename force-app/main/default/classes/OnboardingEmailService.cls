/**
 * Sends the two email notifications required by the spec:
 *  1. "New task assigned" - fired when an Onboarding_Task__c is created.
 *  2. "Reminder" - fired by OnboardingReminderScheduler for tasks that are
 *     still Not Started and due in 2 days.
 *
 * NOTE: Onboarding_Task__c is the detail side of a Master-Detail relationship
 * to Employee__c, so it has NO Owner field of its own (ownership is entirely
 * inherited from the parent in Master-Detail child objects, with no separate
 * OwnerId to query). The "assigned task owner" from the spec is therefore
 * modeled as the Employee's Manager (Employee__r.Manager__r).
 */
public with sharing class OnboardingEmailService {

    /**
     * Emails the Employee's Manager for each newly created onboarding task.
     * Re-queries the tasks to load the Manager's name and email, and skips
     * any task whose Employee has no Manager or whose Manager has no email.
     *
     * @param tasks Newly inserted Onboarding_Task__c records (from trigger context)
     */
    public static void sendTaskCreatedEmails(List<Onboarding_Task__c> tasks) {
        List<Onboarding_Task__c> tasksWithManagers = [
            SELECT Id, Name, Due_Date__c, Employee__r.Manager__r.Email, Employee__r.Manager__r.Name
            FROM Onboarding_Task__c
            WHERE Id IN :tasks
        ];
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (Onboarding_Task__c t : tasksWithManagers) {
            if (t.Employee__r == null || t.Employee__r.Manager__r == null || String.isBlank(t.Employee__r.Manager__r.Email)) {
                continue;
            }
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>{ t.Employee__r.Manager__r.Email });
            mail.setSubject('New Onboarding Task Assigned: ' + t.Name);
            mail.setPlainTextBody(
                'Hi ' + t.Employee__r.Manager__r.Name + ',\n\n' +
                'A new onboarding task has been created for your new hire:\n' +
                'Task: ' + t.Name + '\n' +
                'Due Date: ' + (t.Due_Date__c != null ? t.Due_Date__c.format() : 'N/A') + '\n\n' +
                'Please review it in Salesforce.'
            );
            emails.add(mail);
        }
        sendEmails(emails);
    }

    /**
     * Emails the Employee's Manager a reminder for each task that is due soon.
     * Expects the caller to have already queried Employee__r.Manager__r.Email
     * and Employee__r.Manager__r.Name on each task.
     *
     * @param tasks Onboarding_Task__c records due in 2 days, with Manager fields populated
     */
    public static void sendReminderEmails(List<Onboarding_Task__c> tasks) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (Onboarding_Task__c t : tasks) {
            if (t.Employee__r == null || t.Employee__r.Manager__r == null || String.isBlank(t.Employee__r.Manager__r.Email)) {
                continue;
            }
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>{ t.Employee__r.Manager__r.Email });
            mail.setSubject('Reminder: Onboarding Task Due Soon - ' + t.Name);
            mail.setPlainTextBody(
                'Hi ' + t.Employee__r.Manager__r.Name + ',\n\n' +
                'This is a reminder that the following onboarding task is still Not Started ' +
                'and is due in 2 days:\n' +
                'Task: ' + t.Name + '\n' +
                'Due Date: ' + (t.Due_Date__c != null ? t.Due_Date__c.format() : 'N/A') + '\n\n' +
                'Please follow up as soon as possible.'
            );
            emails.add(mail);
        }
        sendEmails(emails);
    }

    /**
     * Sends the given emails in a single call (one email invocation regardless
     * of list size). Does nothing for an empty list, and skips the actual send
     * during tests so unit tests don't consume the org's daily email limit.
     *
     * @param emails Emails to send
     */
    private static void sendEmails(List<Messaging.SingleEmailMessage> emails) {
        if (emails.isEmpty()) {
            return;
        }
        if (!Test.isRunningTest()) {
            Messaging.sendEmail(emails, false);
        }
    }
}
