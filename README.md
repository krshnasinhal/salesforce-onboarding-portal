# Employee Onboarding Portal — Salesforce Mini Project

This repo implements the mini project spec using an **Apex trigger** for task
generation (stretch goal) instead of a declarative Flow, per your call.

## What's in here (deployable via SFDX)

| Piece | Files |
|---|---|
| Data model (5 custom objects, correct Lookup/Master-Detail) | `force-app/main/default/objects/` |
| Task generation on Employee insert (bulkified) | `EmployeeTrigger` → `OnboardingTaskGenerator.cls` |
| Status roll-up (In Progress / Onboarded) | `OnboardingTaskTrigger` → `OnboardingTaskTriggerHandler.cls` → `StatusRollupService.cls` |
| Email alerts (new task + 2-day reminder) | `OnboardingEmailService.cls` |
| Daily scheduled reminder job | `OnboardingReminderScheduler.cls` (implements `Schedulable`) |
| LWC "Onboarding Progress Tracker" (progress bar, grouped tasks, badges) | `force-app/main/default/lwc/onboardingProgressTracker/` |
| Apex controller behind the LWC's `@wire` | `OnboardingProgressController.cls` |
| Test classes (target ≥85% coverage) | `*Test.cls` + `OnboardingTestDataFactory.cls` |
| Permission set for full CRUD + Apex/LWC access | `Onboarding_Portal_Access.permissionset-meta.xml` |

## What's **not** in here — and why

Two pieces of the spec are pure clicks-in-Setup deliverables (Screen Flow,
Reports/Dashboard). I can't drive the Salesforce UI directly, and hand-written
Flow XML is fragile enough that a malformed file just fails to deploy — so
below are exact build steps instead. They're genuinely quick (15–30 min each)
once the code above is deployed.

---

## 1. Deploy the code

```bash
# from the onboarding-portal/ folder
sf org login web -a onboardingDevOrg          # authenticate to your Developer org
sf project deploy start --source-dir force-app -o onboardingDevOrg
sf org assign permset -n Onboarding_Portal_Access -o onboardingDevOrg
sf apex run test --test-level RunLocalTests -o onboardingDevOrg --result-format human
```

Then, as an Admin (or via the permission set above applied to yourself),
create a Lightning App / add the objects' tabs so you can navigate to them.

## 2. Seed sample data

Create 2 `Onboarding_Template__c` records ("Engineering Onboarding",
"Sales Onboarding") with a few `Template_Task__c` children each — exactly
like the ones `OnboardingTestDataFactory` creates in tests. Then insert an
`Employee__c` with a matching Department and watch tasks auto-generate.

## 3. Build the HR Screen Flow (manual, Setup > Flows > New Flow > Screen Flow)

This satisfies requirement 3 (Multi-Step Screen Flow for HR).

1. **New Flow → Screen Flow.**
2. **Screen 1 — "Employee Details":**
   - Text input → `Name`
   - Email input → `Email`
   - Picklist choice set sourced from `Employee__c.Department__c` → `Department`
   - Date input → `Joining Date`
   - Lookup component (or a Record Choice Set of User) → `Manager`
3. **Screen 2 — "Select Template" (optional, since the trigger auto-matches
   by Department anyway):**
   - Get Records: `Onboarding_Template__c` where `Department__c` = `{!Department}`
   - Display the matched template name as read-only text, or let HR override
     via a dropdown of all templates.
4. **Screen 3 — "Confirm & Submit":** Display Text summarizing the entered
   values.
5. **Create Records element:** create one `Employee__c` record from the
   Screen 1 inputs. **This single insert is what fires `EmployeeTrigger`**,
   which generates the tasks — so you don't need a separate "generate tasks"
   step in the Flow; the Apex trigger already handles it.
6. Activate the Flow, then add it to a Lightning App Page or the Employee
   list view's action bar so HR can launch it.

## 4. Reports & Dashboard (manual, Setup > Reports / Dashboards)

**Report 1 — Average time-to-onboard by Department:**
- Report type: Employees (custom report type on `Employee__c`, or a plain
  `Employee__c` report if no relationship rollup needed).
- Add a formula field on `Employee__c` first: `Onboarded_Date__c` — or simpler,
  use the report's built-in row-level formula: `Joining_Date__c` vs
  `LastModifiedDate` won't be accurate; cleanest is to add a real
  `Onboarded_Date__c` Date field, populate it in `StatusRollupService` when
  status flips to Onboarded, then report on
  `AVG(Onboarded_Date__c - Joining_Date__c)` grouped by `Department__c`.
  *(Optional code change — see note below.)*

**Report 2 — Open/overdue tasks grouped by Task Type:**
- Report type: `Onboarding_Task__c`.
- Filter: `Status__c != Completed`.
- Group by: `Task_Type__c`.
- Add a bucket field or filter for `Due_Date__c < TODAY` to isolate overdue.

**Dashboard:** New Dashboard → add a bar chart component sourced from Report 1
and a table component sourced from Report 2 → title it "HR Onboarding
Dashboard".

> **Optional code addition for Report 1:** add an `Onboarded_Date__c` Date
> field to `Employee__c`, then in `StatusRollupService.rollupEmployeeStatus`,
> set `emp.Onboarded_Date__c = Date.today();` alongside
> `emp.Status__c = 'Onboarded';`. I left this out of the base build since it
> wasn't explicitly in the field list — add it if you want Report 1 to be
> exact rather than approximated from `LastModifiedDate`.

## 5. Stretch goals not built here

- **Experience Cloud page:** requires enabling Digital Experiences in Setup
  (org-level toggle I can't flip for you) and choosing a template — genuinely
  a UI-driven setup step.
- **Document upload via `lightning-file-upload`:** straightforward to add —
  a new LWC with `<lightning-file-upload record-id={recordId} object-api-name="Document__c">`
  bound to the `Document__c` object. Say the word and I'll build that
  component the same way as the progress tracker.
- **Push to GitHub:** `git init && git add . && git commit -m "Onboarding portal" && git remote add origin <your-repo-url> && git push -u origin main` from this folder.

## Design notes / trade-offs (good talking points for your demo)

- **Master-Detail vs Lookup:** `Onboarding_Task__c → Employee__c` and
  `Template_Task__c → Onboarding_Template__c` are Master-Detail because
  children have no meaning without the parent (cascade delete, roll-up
  summary eligibility). `Document__c → Employee__c` is a Lookup since a
  document could plausibly outlive/be reassigned independent of the employee
  record's lifecycle, and Employee already has one Master-Detail child
  (avoids the 2-MD-parent complexity where it isn't needed).
- **Apex trigger vs Flow for generation:** chosen per your preference — the
  trade-off is more control and testability (bulk-safe by construction, unit
  tested) vs. Flow's lower barrier to entry for non-developers to modify
  later.
- **"Assigned task owner" = record Owner:** the spec doesn't define an
  explicit owner field, so this build uses the standard `OwnerId` every
  custom object gets for free — set it when creating templates/tasks (or
  extend `OnboardingTaskGenerator` to set `OwnerId` based on `Task_Type__c`
  → a queue or specific user, which is the natural next iteration).
