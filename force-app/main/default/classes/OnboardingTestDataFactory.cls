/**
 * Shared test data builders used by all onboarding test classes.
 */
@isTest
public class OnboardingTestDataFactory {

    /**
     * Inserts an active (Version 1) Onboarding Template for a department with
     * three Template Tasks: Send Welcome Email (HR, 0 days), Provision Laptop
     * (IT, 3 days) and 1:1 With Manager (Manager, 5 days).
     *
     * @param department Department value for the template
     * @return The inserted Onboarding_Template__c
     */
    public static Onboarding_Template__c createTemplateWithTasks(String department) {
        Onboarding_Template__c tmpl = new Onboarding_Template__c(
            Name = department + ' Onboarding',
            Department__c = department,
            Active__c = true,
            Version__c = 1
        );
        insert tmpl;

        List<Template_Task__c> tasks = new List<Template_Task__c>{
            new Template_Task__c(
                Name = 'Send Welcome Email',
                Task_Type__c = 'HR',
                Days_to_Complete__c = 0,
                Onboarding_Template__c = tmpl.Id
            ),
            new Template_Task__c(
                Name = 'Provision Laptop',
                Task_Type__c = 'IT',
                Days_to_Complete__c = 3,
                Onboarding_Template__c = tmpl.Id
            ),
            new Template_Task__c(
                Name = '1:1 With Manager',
                Task_Type__c = 'Manager',
                Days_to_Complete__c = 5,
                Onboarding_Template__c = tmpl.Id
            )
        };
        insert tasks;

        return tmpl;
    }

    /**
     * Builds (does not insert) an Employee with status Offer Accepted and the
     * running user as Manager, so callers control when the trigger fires.
     *
     * @param department  Department value for the Employee
     * @param joiningDate Joining date used to calculate task due dates
     * @return An unsaved Employee__c record
     */
    public static Employee__c buildEmployee(String department, Date joiningDate) {
        return new Employee__c(
            Name = 'Test Employee',
            Email__c = 'test.employee@example.com',
            Department__c = department,
            Joining_Date__c = joiningDate,
            Status__c = 'Offer Accepted',
            Manager__c = UserInfo.getUserId()
        );
    }
}
