# Developer Guide

This guide provides step-by-step instructions for implementing asynchronous job processing using the Async Job Load Balancer Framework. You'll learn how to create custom batch and queueable jobs, manage job requests, handle errors, and leverage advanced features.

---

## Table of Contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Understanding Core Components](#understanding-core-components)
- [Tutorial 1: Building Your First Batch Job](#tutorial-1-building-your-first-batch-job)
- [Tutorial 2: Building Your First Queueable Job](#tutorial-2-building-your-first-queueable-job)
- [Tutorial 3: Working with Payloads](#tutorial-3-working-with-payloads)
- [Best Practices](#best-practices)
- [Common Patterns](#common-patterns)

---

## Introduction

The Async Job Load Balancer Framework simplifies asynchronous job management in Salesforce by providing:

- **Abstract base classes** - `BatchableJob` and `QueueableJob` that handle lifecycle events automatically
- **Automatic load balancing** - Respects flex queue limits and system capacity
- **Built-in monitoring** - Track job status from request to completion
- **Error handling** - Automatic error capture and logging

By the end of this guide, you'll be able to create production-ready async jobs that scale efficiently.

---

## Prerequisites

### Required Environment

- Salesforce Developer/Scratch Org or Sandbox (API version 62.0 or higher)
- SFDX CLI installed (optional, for deployment)
- Basic understanding of Apex programming
- Familiarity with Batch Apex and Queueable Apex concepts

### Installation Steps

If you haven't installed the framework yet, follow these steps:

1. **Clone the repository**
   ```bash
   git clone https://github.com/akohan91/libak-salesforce-async-job-load-balancer.git
   cd libak-salesforce-async-job-load-balancer
   ```

2. **Deploy to your org**
   ```bash
   sfdx force:source:deploy -p force-app -u YourOrgAlias
   ```

3. **Assign permission set** (if needed)
   ```bash
   sfdx force:user:permset:assign -n AsyncLoadBalancer -u YourOrgAlias
   ```

4. **Verify installation**
   - Open Salesforce Setup
   - Navigate to Platform Events → Check for `AsyncJob__e`
   - Navigate to Objects → Check for `AsyncJobRequest__c`

---

## Understanding Core Components

Before diving into implementation, let's understand the key components:

### AsyncJobRequest__c

Custom object that stores job requests. Key fields:

- `JobName__c` - Fully qualified class name of your job
- `JobStatus__c` - Current status (Waiting, Pending, Processing, Completed, Failed)
- `RecordTypeId` - Batchable or Queueable
- `BatchSize__c` - Batch size (for batch jobs only)
- `Payload__c` - JSON string containing job parameters
- `JobId__c` - Salesforce Async Apex Job ID
- `ErrorMessage__c` - Error details if job fails

### AsyncJob__e

Platform Event for inter-component communication. Actions include:

- `QUEUE_JOB` - Trigger job execution
- `CHANGE_STATUS` - Update job status
- `ADD_ERROR` - Log error message

### Base Classes

- `BatchableJob` - Extend for batch jobs
- `QueueableJob` - Extend for queueable jobs
- `AsyncJob` - Base class providing common functionality (payload handling, event creation)

### Service Classes

- `AsyncJobEventService` - Routes events to appropriate handlers
- `AsyncJobRequestService` - Manages job request operations
- `BatchableJobProcessor` - Executes batch jobs
- `QueueableJobProcessor` - Executes queueable jobs

---

## Tutorial 1: Building Your First Batch Job

In this tutorial, we'll create a batch job that processes Account records and updates their descriptions.

### Goal

Create a batch job that:
- Queries all Account records
- Appends a timestamp to each Account's description
- Processes records in batches of 200
- Tracks execution status automatically

### Step 1: Create the Batch Job Class

Create a new Apex class that extends `BatchableJob`:

```apex
public with sharing class UpdateAccountDescriptionBatch extends BatchableJob {
    
    protected override Database.QueryLocator doStart(Database.BatchableContext bc) {
        // Return query locator - this method is called once at the start
        return Database.getQueryLocator([
            SELECT Id, Name, Description 
            FROM Account
        ]);
    }

    protected override void doExecute(Database.BatchableContext bc, List<SObject> scope) {
        // Process each batch - this method is called for each batch
        List<Account> accountsToUpdate = new List<Account>();
        
        for (Account acc : (List<Account>) scope) {
            String timestamp = String.valueOf(Datetime.now());
            acc.Description = (acc.Description != null ? acc.Description + '\n' : '') 
                            + 'Updated on: ' + timestamp;
            accountsToUpdate.add(acc);
        }
        
        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }

    protected override void doFinish(Database.BatchableContext bc) {
        // Optional: Cleanup or post-processing logic
        System.debug('Batch job completed successfully');
    }
}
```

**What's happening:**

1. **doStart()** - Returns a QueryLocator that fetches all Accounts. The framework publishes a `Processing` status event automatically.
2. **doExecute()** - Processes each batch of records. This is where your business logic lives.
3. **doFinish()** - Called after all batches complete. Use for cleanup or follow-up actions.

<blockquote><b>NOTE:</b> You don't need to manually publish status events. The BatchableJob base class handles this automatically, publishing events for Processing, Completed, and Failed states.</blockquote>

### Step 2: Create a Job Request

Now trigger the batch job by inserting an `AsyncJobRequest__c` record:

```apex
AsyncJobRequest__c jobRequest = new AsyncJobRequest__c(
    JobName__c = 'UpdateAccountDescriptionBatch',
    RecordTypeId = AsyncJobRequestConstants.recordType.BatchableId,
    BatchSize__c = 200
);
insert jobRequest;
```

**What's happening:**

1. `JobName__c` - Must match your class name exactly (case-sensitive)
2. `RecordTypeId` - Use the Batchable record type ID from constants
3. `BatchSize__c` - Number of records per batch (max 2000)

### Step 3: Monitor Execution

Navigate to the Async Job Requests tab in Salesforce to see your job:

- **Status** will progress: Waiting → Pending → Processing → Completed
- **Requested Time** shows when the request was created
- **Processed Time** shows when execution started
- **Finished Time** shows when it completed
- **Job ID** links to the standard Apex Jobs page

---

## Tutorial 2: Building Your First Queueable Job

In this tutorial, we'll create a queueable job that sends email notifications.

### Goal

Create a queueable job that:
- Retrieves high-value opportunities closing soon
- Sends email notifications to account owners
- Can be chained for additional processing

### Step 1: Create the Queueable Job Class

```apex
public with sharing class OpportunityNotificationQueueable extends QueueableJob {
    
    protected override void doExecute(QueueableContext context) {
        // Query opportunities closing in the next 7 days
        List<Opportunity> opportunities = [
            SELECT Id, Name, Amount, CloseDate, Owner.Email, Account.Name
            FROM Opportunity
            WHERE CloseDate = NEXT_N_DAYS:7
            AND Amount > 100000
            AND IsClosed = false
            LIMIT 100
        ];
        
        if (opportunities.isEmpty()) {
            return;
        }
        
        // Send email notifications
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        for (Opportunity opp : opportunities) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{ opp.Owner.Email });
            email.setSubject('High-Value Opportunity Closing Soon: ' + opp.Name);
            email.setPlainTextBody(
                'The opportunity "' + opp.Name + '" for account "' + opp.Account.Name + 
                '" is closing on ' + opp.CloseDate.format() + 
                ' with amount $' + opp.Amount.format() + '.\n\n' +
                'Please ensure all follow-up activities are completed.'
            );
            emails.add(email);
        }
        
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }
}
```

**What's happening:**

1. **doExecute()** - Contains all the queueable logic. No start/finish methods needed.
2. **Automatic callouts** - The base class is already configured with `Database.AllowsCallouts`
3. **Error handling** - Using the Finalizer pattern, the base class automatically captures and logs any exceptions

<blockquote><b>NOTE:</b> Queueable jobs use the Finalizer interface for error handling. If an exception occurs, the framework automatically publishes error events and updates the job status to Failed.</blockquote>

### Step 2: Create a Job Request

```apex
AsyncJobRequest__c jobRequest = new AsyncJobRequest__c(
    JobName__c = 'OpportunityNotificationQueueable',
    RecordTypeId = AsyncJobRequestConstants.recordType.QueueableId
);
insert jobRequest;
```

**What's happening:**

1. For queueable jobs, you don't need to specify `BatchSize__c`
2. The framework enqueues the job automatically when capacity is available

### Step 3: Verify Execution

Check the Async Job Requests tab to monitor:
- Job status changes
- Execution timestamps
- Any error messages if the job fails

---

## Tutorial 3: Working with Payloads

Often, you need to pass parameters to your jobs. The framework provides built-in payload support.

### Goal

Create a batch job that accepts parameters:
- Record Type Developer Name to filter Accounts
- Custom message to add to descriptions

### Step 1: Create a Batch Job with Payload Handling

```apex
public with sharing class ParameterizedAccountBatch extends BatchableJob {
    
    private String recordTypeName;
    private String customMessage;
    
    protected override Database.QueryLocator doStart(Database.BatchableContext bc) {
        // Parse the payload in doStart
        if (String.isNotBlank(this.payload)) {
            Map<String, Object> payloadMap = (Map<String, Object>) JSON.deserializeUntyped(this.payload);
            this.recordTypeName = (String) payloadMap.get('recordTypeName');
            this.customMessage = (String) payloadMap.get('customMessage');
        }
        
        // Build dynamic query based on payload
        String query = 'SELECT Id, Name, Description FROM Account';
        
        if (String.isNotBlank(this.recordTypeName)) {
            Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get(this.recordTypeName)
                .getRecordTypeId();
            query += ' WHERE RecordTypeId = \'' + recordTypeId + '\'';
        }
        
        return Database.getQueryLocator(query);
    }

    protected override void doExecute(Database.BatchableContext bc, List<SObject> scope) {
        List<Account> accountsToUpdate = new List<Account>();
        
        for (Account acc : (List<Account>) scope) {
            acc.Description = (acc.Description != null ? acc.Description + '\n' : '') 
                            + this.customMessage;
            accountsToUpdate.add(acc);
        }
        
        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }

    protected override void doFinish(Database.BatchableContext bc) {
        System.debug('Parameterized batch completed: ' + this.recordTypeName);
    }
}
```

**What's happening:**

1. The `payload` property is inherited from `AsyncJob` base class
2. Parse JSON payload in `doStart()` to access parameters
3. Use parameters to customize job behavior

### Step 2: Create a Job Request with Payload

```apex
// Prepare payload as JSON
Map<String, Object> payloadMap = new Map<String, Object>{
    'recordTypeName' => 'PersonAccount',
    'customMessage' => 'Processed by automated batch job - High Priority'
};

AsyncJobRequest__c jobRequest = new AsyncJobRequest__c(
    JobName__c = 'ParameterizedAccountBatch',
    RecordTypeId = AsyncJobRequestConstants.recordType.BatchableId,
    BatchSize__c = 200,
    Payload__c = JSON.serialize(payloadMap)
);
insert jobRequest;
```

**What's happening:**

1. Create a Map with your parameters
2. Serialize to JSON string
3. Set the `Payload__c` field
4. The framework passes this to your job automatically via `withPayload()` method

<blockquote><b>NOTE:</b> The Payload__c field is a Long Text Area with 131,072 character limit. For complex payloads, consider storing references (IDs, names) instead of large data structures.</blockquote>

---

## Best Practices

### 1. Job Design

**Keep Jobs Focused**
- Each job should have a single, well-defined purpose
- Avoid mixing unrelated business logic in one job
- Break complex operations into multiple smaller jobs

**Bulkify Your Code**
- Always process collections, not individual records
- Avoid SOQL/DML inside loops
- Use Maps for efficient lookups

**Handle Large Data Volumes**
- For batch jobs, use appropriate batch sizes (typically 200-500)
- Consider data volume when setting batch size
- Test with realistic data volumes

### 2. Error Handling

**Fail Gracefully**
- Use `Database.update(records, false)` for partial success scenarios
- Log detailed error information for troubleshooting
- Implement retry logic for transient errors

**Monitor Job Health**
- Regularly check for failed jobs
- Set up alerts for critical job failures
- Review error messages and patterns

---

## Common Patterns

### Pattern 1: Job Chaining

Execute multiple jobs in sequence:

```apex
public class Step1Batch extends BatchableJob {
    protected override void doFinish(Database.BatchableContext bc) {
        // Start next job in the chain
        AsyncJobRequest__c nextJob = new AsyncJobRequest__c(
            JobName__c = 'Step2Batch',
            RecordTypeId = AsyncJobRequestConstants.recordType.BatchableId,
            BatchSize__c = 200
        );
        insert nextJob;
    }
}
```

---

## Next Steps

Now that you've completed the tutorials, you're ready to:

1. **Explore the [API Reference](API_Reference.md)** - Deep dive into all available classes and methods
2. **Review the Demo App** - Check the `demo-app` directory for additional examples
3. **Build Your Own Jobs** - Apply these patterns to your specific use cases
4. **Contribute** - Share your improvements with the community

For questions or issues, please open a GitHub issue or reach out to the community.

Happy coding!