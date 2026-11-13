/**
 * Apex controller for the onboardingProgressTracker LWC.
 * Returns the tasks for a given Employee plus a pre-computed percent-complete
 * so the component doesn't have to do that math itself.
 */
public with sharing class OnboardingProgressController {

    /**
     * Data returned to the LWC: the Employee's tasks and completion figures.
     */
    public class ProgressResult {
        /** Percentage of tasks completed, rounded to a whole number (0-100). */
        @AuraEnabled public Integer percentComplete;
        /** Total number of onboarding tasks for the Employee. */
        @AuraEnabled public Integer totalTasks;
        /** Number of tasks with Status = Completed. */
        @AuraEnabled public Integer completedTasks;
        /** The Employee's tasks, ordered by type then due date. */
        @AuraEnabled public List<Onboarding_Task__c> tasks;
    }

    /**
     * Loads an Employee's onboarding tasks and calculates their progress.
     * Cacheable so the LWC can call it with @wire. Uses WITH SECURITY_ENFORCED
     * so the running user's field- and object-level security is respected.
     *
     * @param employeeId Id of the Employee__c record shown on the page
     * @return ProgressResult with the tasks, counts and percent complete
     *         (0% when the Employee has no tasks)
     */
    @AuraEnabled(cacheable=true)
    public static ProgressResult getProgress(Id employeeId) {
        List<Onboarding_Task__c> tasks = [
            SELECT Id, Name, Task_Type__c, Status__c, Due_Date__c
            FROM Onboarding_Task__c
            WHERE Employee__c = :employeeId
            WITH SECURITY_ENFORCED
            ORDER BY Task_Type__c, Due_Date__c
        ];

        Integer total = tasks.size();
        Integer completed = 0;
        for (Onboarding_Task__c t : tasks) {
            if (t.Status__c == 'Completed') {
                completed++;
            }
        }

        ProgressResult result = new ProgressResult();
        result.tasks = tasks;
        result.totalTasks = total;
        result.completedTasks = completed;
        result.percentComplete = total == 0 ? 0 : Integer.valueOf(Math.round((completed * 100.0) / total));
        return result;
    }
}
