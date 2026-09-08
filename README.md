# Salesforce Employee Onboarding Portal

A Salesforce application that automates the employee onboarding process — from creating a new hire to generating their onboarding tasks, tracking progress, and reporting on time-to-onboard. Built on a custom data model with Apex trigger automation, a Lightning Web Component, a Screen Flow, and reporting dashboards.

## What it does

When HR creates a new employee, the app automatically generates a checklist of onboarding tasks based on the employee's department, notifies the responsible manager, tracks completion in real time, and marks the employee as fully onboarded once every task is done — recording the date it happened.

## Key features

- **Automated task generation** — On employee creation, an Apex trigger matches the employee's department to an onboarding template and generates the corresponding tasks (bulkified to handle many employees at once).
- **Automatic status tracking** — The employee's status flips to *In Progress* when the first task is created, and to *Onboarded* (with an onboarded date stamped) once all tasks are marked Completed.
- **Email notifications** — The responsible manager is emailed when tasks are generated, and a scheduled job sends reminders for tasks due within two days.
- **Progress tracker (LWC)** — A Lightning Web Component on the Employee record page shows a live progress bar and tasks grouped by type (HR / IT / Manager) with status badges.
- **HR intake flow** — A Screen Flow lets HR create a new employee through a guided form, triggering the full automation.
- **Reports & dashboard** — An HR dashboard combining open/overdue tasks by type and average time-to-onboard by department.

## Data model

| Object | Purpose | Relationship |
|--------|---------|--------------|
| `Employee__c` | The new hire record | — |
| `Onboarding_Task__c` | A task assigned to an employee | Master-Detail → Employee |
| `Onboarding_Template__c` | A reusable onboarding checklist per department | — |
| `Template_Task__c` | A task definition within a template | Master-Detail → Template |
| `Document__c` | Documents attached to an employee | Lookup → Employee |

## Apex automation

| Class / Trigger | Responsibility |
|-----------------|----------------|
| `EmployeeTrigger` + `OnboardingTaskGenerator` | Generate tasks from the matching department template on employee insert |
| `OnboardingTaskTrigger` + `OnboardingTaskTriggerHandler` | Flip employee to *In Progress* on first task |
| `StatusRollupService` | Flip employee to *Onboarded* and stamp the onboarded date when all tasks are complete |
| `OnboardingEmailService` | Email the employee's manager |
| `OnboardingReminderScheduler` | Schedulable job for due-soon task reminders |
| `OnboardingProgressController` | Apex controller backing the progress tracker LWC |

All automation is covered by Apex test classes (`OnboardingTaskGeneratorTest`, `OnboardingEmailServiceTest`, `OnboardingProgressControllerTest`, `StatusRollupServiceTest`, `OnboardingReminderSchedulerTest`).

## Tech stack

- Salesforce Platform (Developer Edition)
- Apex (triggers, service classes, schedulable jobs, unit tests)
- Lightning Web Components
- Flow Builder (Screen Flow)
- Salesforce CLI (`sf`) for source-driven deployment

## Project structure

```
force-app/main/default/
├── classes/         Apex classes and tests
├── triggers/        Apex triggers
├── lwc/             Lightning Web Component (onboardingProgressTracker)
├── objects/         Custom objects and fields
└── permissionsets/  Permission set for portal access
manifest/package.xml
sfdx-project.json
```

## Deployment

Deploy to a scratch or Developer Edition org with the Salesforce CLI:

```bash
sf project deploy start --source-dir force-app
```

Then create an onboarding template with template tasks for a department, and create an employee in that department to see the automation run.

## Notes

This project uses an Apex trigger-based approach for task generation (rather than record-triggered Flows) to keep the generation logic bulkified and fully unit-tested.
