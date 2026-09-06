/**
 * @wire-able controller for the onboardingProgressTracker LWC.
 * Returns the tasks for a given Employee plus a pre-computed percent-complete
 * so the component doesn't have to do that math itself.
 */
public with sharing class OnboardingProgressController {

    public class ProgressResult {
        @AuraEnabled public Integer percentComplete;
        @AuraEnabled public Integer totalTasks;
        @AuraEnabled public Integer completedTasks;
        @AuraEnabled public List<Onboarding_Task__c> tasks;
    }

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
