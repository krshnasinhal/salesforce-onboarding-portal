# Salesforce Employee Onboarding Portal

A Salesforce application that automates the employee onboarding process — from creating a new hire to generating their onboarding tasks, tracking progress, and reporting on time-to-onboard. Built on a custom data model with Apex trigger automation, a Lightning Web Component, a Screen Flow, and reporting dashboards.

## What it does

When HR creates a new employee, the app automatically generates a checklist of onboarding tasks based on the employee's department, notifies the responsible manager, tracks completion in real time, and marks the employee as fully onboarded once every task is done — recording the date it happened.

## Key features

- **Automated task generation** — When an employee is created, or their department is changed, an Apex trigger matches the department to the highest active version of its onboarding template and generates the corresponding tasks. Existing tasks are kept and never duplicated (bulkified to handle many employees at once).
- **Automatic status tracking** — The employee's status flips to *In Progress* when the first task is created, and to *Onboarded* (with an onboarded date stamped) once all tasks are marked Completed.
- **Email notifications** — The responsible manager is emailed when tasks are generated, and a scheduled job sends reminders for tasks due within two days.
- **Progress tracker (LWC)** — A Lightning Web Component on the Employee record page shows a live progress bar and tasks grouped by type (HR / IT / Manager) with status badges.
- **HR intake flow** — A Screen Flow lets HR create a new employee through a guided form, triggering the full automation.
- **Template versioning** — Templates have *Version* and *Active* fields, so HR can roll out a new checklist version without editing the old one.
- **Role-based access** — Separate permission sets for HR and Managers, with no View All Records.
- **Reports & dashboard** — An HR dashboard combining open/overdue tasks by type and average time-to-onboard by department.

## Data model

| Object | Purpose | Relationship |
|--------|---------|--------------|
| `Employee__c` | The new hire record | — |
| `Onboarding_Task__c` | A task assigned to an employee | Master-Detail → Employee |
| `Onboarding_Template__c` | A reusable, versioned onboarding checklist per department | — |
| `Template_Task__c` | A task definition within a template | Master-Detail → Template |
| `Document__c` | Documents attached to an employee | Lookup → Employee |

## Apex automation

| Class / Trigger | Responsibility |
|-----------------|----------------|
| `EmployeeTrigger` + `OnboardingTaskGenerator` | Generate tasks from the highest active template for the employee's department, on insert and on department change |
| `OnboardingTaskTrigger` + `OnboardingTaskTriggerHandler` | Flip employee to *In Progress* on first task |
| `StatusRollupService` | Flip employee to *Onboarded* and stamp the onboarded date when all tasks are complete |
| `OnboardingEmailService` | Email the employee's manager |
| `OnboardingReminderScheduler` | Schedulable job for due-soon task reminders |
| `OnboardingProgressController` | Apex controller backing the progress tracker LWC |

All automation is covered by Apex test classes (`OnboardingTaskGeneratorTest`, `OnboardingEmailServiceTest`, `OnboardingProgressControllerTest`, `StatusRollupServiceTest`, `OnboardingReminderSchedulerTest`), with every project class at 91–100% coverage. All classes are documented with ApexDoc.

## Permission sets

| Permission set | For | Access |
|----------------|-----|--------|
| `Onboarding_Portal_Access` | HR / onboarding admins | Full CRUD on onboarding objects, including templates |
| `Onboarding_Manager_Access` | Managers | Read Employees, read/edit Onboarding Tasks, progress tracker. No template access |

Neither grants View All Records; visibility comes from org-wide defaults and sharing.

## Why a custom task object?

`Onboarding_Task__c` is a custom object rather than the standard Task so it can be the detail side of a Master-Detail relationship to Employee (cascade delete, inherited sharing, roll-ups), hold custom lookups, avoid Activity archiving, and get its own report type. See [DEMO.md](DEMO.md) for the full comparison.

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
├── flows/          HR intake Screen Flow
├── reports/        Onboarding reports
├── dashboards/     HR Onboarding Dashboard
└── permissionsets/  HR and Manager permission sets
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

See [DEMO.md](DEMO.md) for a feature-by-feature walkthrough.

This project uses an Apex trigger-based approach for task generation (rather than record-triggered Flows) to keep the generation logic bulkified and fully unit-tested.
