/**
 * Daily scheduled job (Req 4b): finds Onboarding_Task__c records that are
 * still "Not Started" and due in exactly 2 days, then sends a reminder email
 * to each task's Employee's Manager (via OnboardingEmailService).
 *
 * Schedule from Anonymous Apex / Setup > Scheduled Jobs, e.g.:
 *   String cronExpr = '0 0 6 * * ?'; // every day at 6:00 AM
 *   System.schedule('Onboarding Task Reminders', cronExpr, new OnboardingReminderScheduler());
 */
public with sharing class OnboardingReminderScheduler implements Schedulable {

    /**
     * Runs each time the scheduled job fires. Queries all Not Started tasks
     * due exactly 2 days from today (with their Manager's name and email)
     * and passes them to OnboardingEmailService in one batch.
     *
     * @param ctx Schedulable context supplied by the platform (not used)
     */
    public void execute(SchedulableContext ctx) {
        Date reminderDate = Date.today().addDays(2);

        List<Onboarding_Task__c> dueSoonTasks = [
            SELECT Id, Name, Due_Date__c, Employee__r.Manager__r.Email, Employee__r.Manager__r.Name
            FROM Onboarding_Task__c
            WHERE Status__c = 'Not Started'
              AND Due_Date__c = :reminderDate
        ];

        if (!dueSoonTasks.isEmpty()) {
            OnboardingEmailService.sendReminderEmails(dueSoonTasks);
        }
    }
}
