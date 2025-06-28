# Async Job Load Balancer Framework

## Overview

This framework provides a robust, event-driven mechanism for managing and load-balancing asynchronous Apex jobs (Batchable and Queueable) in Salesforce. It leverages custom objects, platform events, and Apex classes to queue, execute, monitor, and handle errors for asynchronous jobs, ensuring optimal resource utilization and extensibility.

---

## Architecture

### Key Components

- **AsyncJobRequest__c**: Custom object representing a job request, with fields for status, payload, job type, and tracking information.
- **AsyncJob__e**: Platform Event used to communicate job actions, status changes, and errors between components.
- **Apex Classes**: Encapsulate logic for job execution, event handling, and job request management.
- **Triggers**: Listen for new job requests and platform events, initiating processing as needed.

---

## Object Model

### AsyncJobRequest__c

- **Fields**:
  - `JobName__c`: Name of the Apex class to execute.
  - `JobStatus__c`: Status (Waiting, Pending, Processing, Completed, Failed).
  - `BatchSize__c`: Batch size for batch jobs.
  - `Payload__c`: Serialized parameters (e.g., JSON).
  - `JobId__c`: Associated Apex job ID.
  - `RequestedTime__c`, `ProcessedTime__c`, `FinishedTime__c`: Timestamps for job lifecycle.
  - `ErrorMessage__c`: Error details if job fails.

- **Record Types**:
  - `Batchable`
  - `Queueable`

### AsyncJob__e

- **Fields**:
  - `Action__c`: Event action (ADD_ERROR, QUEUE_JOB, CHANGE_STATUS).
  - `AsyncJobId__c`: Related Apex job ID.
  - `JobRequestId__c`, `JobRequestTypeId__c`: Reference to job request and its type.
  - `Payload__c`: Event payload (status change, error message, etc.).

---

## Event Flow

1. **Job Request Creation**:  
   A new `AsyncJobRequest__c` record is inserted (via UI, API, or code).

2. **Trigger: AsyncJobRequestTrigger**  
   - Publishes a `QUEUE_JOB` event for each new job request.

3. **Trigger: AsyncJobEventTrigger**  
   - Listens for `AsyncJob__e` events.
   - Delegates handling to `AsyncJobEventService`.

4. **AsyncJobEventService**  
   - Routes events to appropriate handler based on `Action__c`:
     - `QUEUE_JOB`: Starts job execution.
     - `CHANGE_STATUS`: Updates job status.
     - `ADD_ERROR`: Logs error message.

5. **Job Execution**  
   - `BatchableJobExecutor` or `QueueableJobExecutor` picks up the job request, instantiates the specified Apex class, and enqueues or executes the job.
   - Job status and timestamps are updated accordingly.

6. **Job Lifecycle Events**  
   - As jobs progress or fail, platform events are published to update status or log errors.
   - Completed or failed jobs may trigger new job executions if queue space is available.

---

## Extension Points

- **Custom Job Classes**:  
  Implement `BatchJob` (for batchable) or `QueueableJob` (for queueable) and reference the class name in `JobName__c`.

- **Event Handlers**:  
  Implement `IAsyncJobEventHandler` and register in `AsyncJobEventService` for custom event actions.

- **Executors**:  
  Implement `IAsyncJobExecutor` for new job types or custom execution logic.

---

## Key Classes

- **AsyncJobRequest**: Wrapper for `AsyncJobRequest__c` with fluent setters and update logic.
- **AsyncJobRequestSelector**: Query utility for job requests.
- **AsyncJobRequestDistributor**: Groups job requests by type.
- **BatchJob / QueueableJob**: Abstract base classes for custom jobs.
- **BatchableJobExecutor / QueueableJobExecutor**: Execute jobs based on type.
- **AsyncJobEventService**: Central event router.
- **ErrorJobEventHandler / ChangeStatusJobEventHandler / QueueJobEventHandler**: Handle specific event actions.

---

## Getting Started

### 1. Implement a Custom Job

#### Batch Apex Job

To create a custom batch job, extend the `BatchJob` abstract class and implement its methods:

```java
public with sharing class MyBatchJob extends BatchJob {
    protected override Database.QueryLocator doStart(Database.BatchableContext batchContext) {
        // Return a query locator for records to process
        return Database.getQueryLocator([SELECT Id FROM Account]);
    }
    protected override void doExecute(Database.BatchableContext batchContext, List<SObject> scope) {
        // Process each batch of records
        // ...your logic...
    }
    protected override void doFinish(Database.BatchableContext batchContext) {
        // Optional: logic after all batches are processed
    }
}
```

#### Queueable Apex Job

To create a custom queueable job, extend the `QueueableJob` abstract class and implement its method:

```java
public with sharing class MyQueueableJob extends QueueableJob {
    protected override void doExecute(QueueableContext context) {
        // Your queueable logic here
    }
}
```

### 2. Create a Job Request

Insert an `AsyncJobRequest__c` record with the following fields:
- `JobName__c`: The name of your Apex class (e.g., `MyBatchJob` or `MyQueueableJob`)
- `RecordTypeId`: Use the Batchable or Queueable record type
- `BatchSize__c`: (For batch jobs) Specify the batch size
- `Payload__c`: (Optional) Pass parameters as JSON

Example (Apex):

```apex
AsyncJobRequest__c req = new AsyncJobRequest__c(
    JobName__c = 'MyBatchJob',
    RecordTypeId = AsyncJobRequestConstants.recordType.BatchableId,
    BatchSize__c = 100
);
insert req;
```

### 3. Monitor and Extend

- Monitor job status and errors via the Async Job Requests tab.
- Implement additional event handlers by inheriting from `IAsyncJobEventHandler` and registering in `AsyncJobEventService` if needed.

---

## Usage

1. **Create a Job Request**  
   Insert an `AsyncJobRequest__c` record with the appropriate record type, job class name, and parameters.

2. **Implement Custom Jobs**  
   - For batch jobs: Extend `BatchJob`.
   - For queueable jobs: Extend `QueueableJob`.

3. **Monitor and Manage**  
   Use the Async Job Requests tab and related lists to monitor status, errors, and execution history.

---

## Notes

- The framework automatically manages job queueing, execution, and error handling.
- Flex queue space is respected for batch jobs.
- All job status changes and errors are tracked and auditable.

---

## Diagram

```mermaid
flowchart TD
    A[AsyncJobRequest__c Created] --> B[AsyncJobRequestTrigger]
    B --> C[AsyncJob__e (QUEUE_JOB)]
    C --> D[AsyncJobEventTrigger]
    D --> E[AsyncJobEventService]
    E --> F[QueueJobEventHandler]
    F --> G[BatchableJobExecutor/QueueableJobExecutor]
    G --> H[Job Execution]
    H --> I[AsyncJob__e (CHANGE_STATUS/ADD_ERROR)]
    I --> D
```

---
