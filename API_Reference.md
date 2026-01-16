# API Reference

Complete technical reference for all public classes, interfaces, methods, and constants in the Async Job Load Balancer Framework.

---

## Table of Contents

- [Overview](#overview)
- [Constants](#constants)
  - [AsyncJobRequestConstants](#asyncjobrequestconstants)
  - [AsyncJobEventConstants](#asyncjobeventconstants)
- [Interfaces](#interfaces)
  - [IAsyncJobExecutor](#iasyncjobexecutor)
  - [IAsyncJobEventHandler](#iasyncsjobeventhandler)
- [Core Classes](#core-classes)
  - [AsyncJob](#asyncjob)
  - [BatchableJob](#batchablejob)
  - [QueueableJob](#queueablejob)
  - [AsyncJobRequest](#asyncjobrequest)
- [Service Classes](#service-classes)
  - [AsyncJobEventService](#asyncjobeventservice)
  - [AsyncJobRequestService](#asyncjobrequestservice)
  - [BatchableFlexQueueService](#batchableflexqueueservice)
- [Processor Classes](#processor-classes)
  - [BatchableJobProcessor](#batchablejobprocessor)
  - [QueueableJobProcessor](#queueablejobprocessor)
- [Event Handler Classes](#event-handler-classes)
  - [QueueJobEventHandler](#queuejobeventhandler)
  - [ChangeStatusJobEventHandler](#changestatusjobeventhandler)
  - [ErrorJobEventHandler](#errorjobeventhandler)
- [Utility Classes](#utility-classes)
  - [AsyncJobRequestSelector](#asyncjobrequestselector)
  - [AsyncJobRequestDistributor](#asyncjobrequestdistributor)
- [Custom Objects](#custom-objects)
  - [AsyncJobRequest__c](#asyncjobrequest__c)
  - [AsyncJob__e](#asyncjob__e)

---

## Overview

This API reference provides detailed documentation for all public APIs in the framework. Use this reference when:

- Extending the framework with custom implementations
- Understanding method signatures and parameters
- Implementing custom event handlers or executors
- Troubleshooting integration issues

---

## Constants

### AsyncJobRequestConstants

Constants related to async job requests.

#### ERROR_TMPL

```apex
public static final String ERROR_TMPL = '\rError Message:\r{0}\rStack Trace:\r{1}'
```

Template string for formatting error messages with message and stack trace.

#### JobStatus (Enum)

```apex
public enum JobStatus {
    Waiting,
    Pending,
    Processing,
    Completed,
    Failed
}
```

Status values for async job requests:

- `Waiting` - Job request created, waiting to be picked up
- `Pending` - Job enqueued in Salesforce queue
- `Processing` - Job currently executing
- `Completed` - Job finished successfully
- `Failed` - Job encountered an error

#### RecordTypeName (Enum)

```apex
public enum RecordTypeName {
    Batchable,
    Queueable
}
```

Record type names for job requests:

- `Batchable` - For batch apex jobs
- `Queueable` - For queueable apex jobs

#### recordType

```apex
public static RecordType recordType
```

Singleton instance providing access to record type IDs.

##### RecordType.BatchableId

```apex
public Id BatchableId { get; private set; }
```

Record Type ID for Batchable jobs.

##### RecordType.QueueableId

```apex
public Id QueueableId { get; private set; }
```

Record Type ID for Queueable jobs.

---

### AsyncJobEventConstants

Constants for async job events.

#### Action (Enum)

```apex
public enum Action {
    ADD_ERROR,
    QUEUE_JOB,
    CHANGE_STATUS
}
```

Platform Event action types:

- `ADD_ERROR` - Log error message to job request
- `QUEUE_JOB` - Trigger job execution
- `CHANGE_STATUS` - Update job status

---

## Interfaces

### IAsyncJobExecutor

Interface for job executor implementations.

```apex
public interface IAsyncJobExecutor {
    void executeJob();
}
```

#### executeJob()

Execute a job from the queue.

- Parameters: None
- Returns: void
- Implementation: Should retrieve next job from queue and execute it

**When to Implement:**

Implement this interface to create custom job executors for new job types.

**Example:**

```apex
public class CustomJobExecutor implements IAsyncJobExecutor {
    public void executeJob() {
        // Custom execution logic
    }
}
```

---

### IAsyncJobEventHandler

Interface for event handler implementations.

```apex
public interface IAsyncJobEventHandler {
    void handleEvent(AsyncJob__e event);
}
```

#### handleEvent(AsyncJob__e event)

Handle a platform event.

- Parameters:
  - `event` (AsyncJob__e): The platform event to process
- Returns: void

**When to Implement:**

Implement this interface to create custom handlers for new event action types.

**Example:**

```apex
public class CustomEventHandler implements IAsyncJobEventHandler {
    public void handleEvent(AsyncJob__e event) {
        // Custom event handling logic
    }
}
```

---

## Core Classes

### AsyncJob

Base class for all async jobs providing common functionality.

```apex
public with sharing virtual class AsyncJob
```

#### Properties

##### jobPayload

```apex
protected String jobPayload
```

The payload string containing job parameters (typically JSON).

#### Methods

##### withPayload(String payload)

```apex
public AsyncJob withPayload(String payload)
```

Set the job payload.

- Parameters:
  - `payload` (String): JSON string or other serialized parameters
- Returns: (AsyncJob) Current instance for method chaining

**Usage:**

```apex
MyBatchJob job = new MyBatchJob();
job.withPayload('{"recordTypeName": "PersonAccount"}');
```

##### createJobErrorEvent(Exception exc, Id asyncJobId)

```apex
public AsyncJob__e createJobErrorEvent(Exception exc, Id asyncJobId)
```

Create a platform event for job errors.

- Parameters:
  - `exc` (Exception): The exception that occurred
  - `asyncJobId` (Id): The Salesforce Async Apex Job ID
- Returns: (AsyncJob__e) Platform event ready to publish

**Usage:**

Typically called automatically by framework, but can be used manually:

```apex
try {
    // risky operation
} catch (Exception e) {
    EventBus.publish(createJobErrorEvent(e, jobId));
}
```

##### createJobChangeStatusEvent(AsyncJobRequestConstants.JobStatus newStatus, Id asyncJobId)

```apex
public AsyncJob__e createJobChangeStatusEvent(AsyncJobRequestConstants.JobStatus newStatus, Id asyncJobId)
```

Create a platform event for status changes.

- Parameters:
  - `newStatus` (AsyncJobRequestConstants.JobStatus): The new status
  - `asyncJobId` (Id): The Salesforce Async Apex Job ID
- Returns: (AsyncJob__e) Platform event ready to publish

#### Inner Classes

##### ChangeStatusPayload

```apex
public class ChangeStatusPayload {
    public AsyncJobRequestConstants.JobStatus status {get; private set;}
    public Datetime changedDatetime {get; private set;}
}
```

Wrapper for status change information.

###### Constructor

```apex
public ChangeStatusPayload(AsyncJobRequestConstants.JobStatus status, Datetime changedDatetime)
```

- Parameters:
  - `status` (AsyncJobRequestConstants.JobStatus): The new status
  - `changedDatetime` (Datetime): When the status changed

###### json()

```apex
public String json()
```

Serialize payload to JSON string.

- Returns: (String) JSON representation

---

### BatchableJob

Abstract base class for batch apex jobs with automatic lifecycle management.

```apex
public with sharing abstract class BatchableJob extends AsyncJob 
    implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts
```

#### Abstract Methods

##### doStart(Database.BatchableContext batchContext)

```apex
abstract protected Database.QueryLocator doStart(Database.BatchableContext batchContext)
```

Define the query for records to process.

- Parameters:
  - `batchContext` (Database.BatchableContext): Batch context provided by Salesforce
- Returns: (Database.QueryLocator) Query locator for batch processing

**Implementation Required:**

```apex
protected override Database.QueryLocator doStart(Database.BatchableContext bc) {
    return Database.getQueryLocator([SELECT Id FROM Account]);
}
```

##### doExecute(Database.BatchableContext batchContext, List\<SObject\> scope)

```apex
abstract protected void doExecute(Database.BatchableContext batchContext, List<SObject> scope)
```

Process each batch of records.

- Parameters:
  - `batchContext` (Database.BatchableContext): Batch context provided by Salesforce
  - `scope` (List\<SObject\>): Records in current batch
- Returns: void

**Implementation Required:**

```apex
protected override void doExecute(Database.BatchableContext bc, List<SObject> scope) {
    // Process records in scope
}
```

##### doFinish(Database.BatchableContext batchContext)

```apex
abstract protected void doFinish(Database.BatchableContext batchContext)
```

Execute post-processing logic after all batches complete.

- Parameters:
  - `batchContext` (Database.BatchableContext): Batch context provided by Salesforce
- Returns: void

**Implementation Required:**

```apex
protected override void doFinish(Database.BatchableContext bc) {
    // Optional cleanup logic
}
```

#### Implemented Methods

##### start(Database.BatchableContext batchContext)

```apex
public Database.QueryLocator start(Database.BatchableContext batchContext)
```

Standard batch interface method - delegates to `doStart()` with automatic status event publishing.

- Publishes `Processing` status event before calling `doStart()`
- Publishes `Failed` status and error event if exception occurs
- Should not be overridden

##### execute(Database.BatchableContext batchContext, List\<SObject\> scope)

```apex
public void execute(Database.BatchableContext batchContext, List<SObject> scope)
```

Standard batch interface method - delegates to `doExecute()` with automatic error handling.

- Publishes error event if exception occurs
- Should not be overridden

##### finish(Database.BatchableContext batchContext)

```apex
public void finish(Database.BatchableContext batchContext)
```

Standard batch interface method - delegates to `doFinish()` with automatic status event publishing.

- Publishes `Completed` status event after successful finish
- Publishes `Failed` status and error event if exception occurs
- Should not be overridden

#### Features

- **Database.Stateful**: Instance variables persist across batch executions
- **Database.AllowsCallouts**: Can make HTTP callouts
- **Automatic Error Handling**: Exceptions are captured and logged automatically
- **Status Tracking**: Job status updates published automatically

---

### QueueableJob

Abstract base class for queueable apex jobs with automatic lifecycle management.

```apex
public with sharing abstract class QueueableJob extends AsyncJob 
    implements Queueable, Finalizer, Database.AllowsCallouts
```

#### Abstract Methods

##### doExecute(QueueableContext context)

```apex
abstract protected void doExecute(QueueableContext context)
```

Execute queueable job logic.

- Parameters:
  - `context` (QueueableContext): Queueable context provided by Salesforce
- Returns: void

**Implementation Required:**

```apex
protected override void doExecute(QueueableContext context) {
    // Your queueable logic here
}
```

#### Implemented Methods

##### execute(QueueableContext context)

```apex
public void execute(QueueableContext context)
```

Standard queueable interface method - delegates to `doExecute()` with automatic status management.

- Attaches finalizer for error handling
- Publishes `Processing` status event before calling `doExecute()`
- Should not be overridden

##### execute(System.FinalizerContext context)

```apex
public void execute(System.FinalizerContext context)
```

Finalizer implementation for automatic error handling.

- Publishes `Failed` status and error event if unhandled exception occurs
- Publishes `Completed` status event on successful completion
- Should not be overridden

##### attachFinalizer()

```apex
virtual protected void attachFinalizer()
```

Attach the finalizer to the job.

- Can be overridden for testing purposes
- Should not be overridden in production code

#### Features

- **Finalizer Pattern**: Automatic error capture even for unhandled exceptions
- **Database.AllowsCallouts**: Can make HTTP callouts
- **Automatic Status Tracking**: Job status updates published automatically

---

### AsyncJobRequest

Wrapper class for `AsyncJobRequest__c` records with fluent API.

```apex
public with sharing class AsyncJobRequest
```

#### Constructor

```apex
public AsyncJobRequest(AsyncJobRequest__c jobRequestRecord)
```

Create wrapper for a job request record.

- Parameters:
  - `jobRequestRecord` (AsyncJobRequest__c): The record to wrap
  
#### Methods

##### record()

```apex
public AsyncJobRequest__c record()
```

Get the wrapped record.

- Returns: (AsyncJobRequest__c) The wrapped job request record

##### setJobId(Id jobId)

```apex
public AsyncJobRequest setJobId(Id jobId)
```

Set the Salesforce Async Apex Job ID.

- Parameters:
  - `jobId` (Id): The async apex job ID
- Returns: (AsyncJobRequest) Current instance for method chaining

##### setJobStatus(AsyncJob.ChangeStatusPayload statusPayload)

```apex
public AsyncJobRequest setJobStatus(AsyncJob.ChangeStatusPayload statusPayload)
```

Update job status and related timestamp fields.

- Parameters:
  - `statusPayload` (AsyncJob.ChangeStatusPayload): Status change information
- Returns: (AsyncJobRequest) Current instance for method chaining
- Side Effects: Updates `JobStatus__c` and appropriate timestamp field based on status

**Status Field Mapping:**

- `Pending` → Sets `RequestedTime__c`
- `Processing` → Sets `ProcessedTime__c`
- `Completed` → Sets `FinishedTime__c`

##### addErrorMessage(Exception exc)

```apex
public AsyncJobRequest addErrorMessage(Exception exc)
```

Add error message from exception.

- Parameters:
  - `exc` (Exception): The exception that occurred
- Returns: (AsyncJobRequest) Current instance for method chaining

##### addErrorMessage(String errorMessage)

```apex
public AsyncJobRequest addErrorMessage(String errorMessage)
```

Add custom error message.

- Parameters:
  - `errorMessage` (String): The error message to add
- Returns: (AsyncJobRequest) Current instance for method chaining
- Side Effects: Appends to existing `ErrorMessage__c` field

##### updateRecord()

```apex
public AsyncJobRequest updateRecord()
```

Persist changes to the database.

- Returns: (AsyncJobRequest) Current instance for method chaining
- Throws: DML exceptions if update fails

**Usage Example:**

```apex
AsyncJobRequest jobRequest = new AsyncJobRequest(jobRequestRecord);
jobRequest.setJobId(jobId)
          .setJobStatus(new AsyncJob.ChangeStatusPayload(AsyncJobRequestConstants.JobStatus.Pending, Datetime.now()))
          .updateRecord();
```

---

## Service Classes

### AsyncJobEventService

Central service for routing platform events to appropriate handlers.

```apex
public with sharing class AsyncJobEventService
```

#### Properties

##### instance

```apex
public static AsyncJobEventService instance
```

Singleton instance of the service.

#### Methods

##### handleEvent(AsyncJob__e event)

```apex
public void handleEvent(AsyncJob__e event)
```

Route event to appropriate handler based on action.

- Parameters:
  - `event` (AsyncJob__e): The platform event to handle
- Returns: void

**Event Routing:**

- `ADD_ERROR` → `ErrorJobEventHandler`
- `CHANGE_STATUS` → `ChangeStatusJobEventHandler`
- `QUEUE_JOB` → `QueueJobEventHandler`

##### setEventHandler(AsyncJobEventConstants.Action action, IAsyncJobEventHandler handler)

```apex
@TestVisible
private void setEventHandler(AsyncJobEventConstants.Action action, IAsyncJobEventHandler handler)
```

Override event handler for testing.

- Parameters:
  - `action` (AsyncJobEventConstants.Action): The action type
  - `handler` (IAsyncJobEventHandler): Custom handler implementation
- Returns: void
- Visibility: TestVisible only

---

### AsyncJobRequestService

Service for managing async job request operations.

```apex
public class AsyncJobRequestService
```

#### Properties

##### instance

```apex
public static AsyncJobRequestService instance
```

Singleton instance of the service.

#### Methods

##### publishQueueJobEvents(List\<AsyncJobRequest__c\> asyncJobRequests)

```apex
public List<Database.SaveResult> publishQueueJobEvents(List<AsyncJobRequest__c> asyncJobRequests)
```

Publish queue job events for new job requests.

- Parameters:
  - `asyncJobRequests` (List\<AsyncJobRequest__c\>): Job requests to process
- Returns: (List\<Database.SaveResult\>) Results of event publishing
- Side Effects: Publishes `QUEUE_JOB` events for each new job request

##### setBypass()

```apex
@TestVisible
private AsyncJobRequestService setBypass()
```

Enable bypass mode to skip event publishing.

- Returns: (AsyncJobRequestService) Current instance
- Visibility: TestVisible only

##### unsetBypass()

```apex
@TestVisible
private AsyncJobRequestService unsetBypass()
```

Disable bypass mode.

- Returns: (AsyncJobRequestService) Current instance
- Visibility: TestVisible only

---

### BatchableFlexQueueService

Service for managing batch apex flex queue capacity.

```apex
public with sharing class BatchableFlexQueueService
```

#### Properties

##### instance

```apex
public static BatchableFlexQueueService instance
```

Singleton instance of the service.

#### Methods

##### getAvailableFlexQueueSlots()

```apex
public Integer getAvailableFlexQueueSlots()
```

Get the number of available flex queue slots.

- Returns: (Integer) Number of available slots (0-100)
- Logic: Calculates 100 minus the number of batch jobs in "Holding" status

**Usage:**

```apex
Integer availableSlots = BatchableFlexQueueService.instance.getAvailableFlexQueueSlots();
if (availableSlots > 0) {
    // Enqueue batch job
}
```

---

## Processor Classes

### BatchableJobProcessor

Processor for executing batch apex jobs.

```apex
public with sharing class BatchableJobProcessor implements IAsyncJobExecutor
```

#### Methods

##### executeJob()

```apex
public void executeJob()
```

Execute the next batch job in the queue.

- Returns: void
- Logic:
  1. Check flex queue capacity
  2. Retrieve next waiting batch job request
  3. Instantiate job class by name
  4. Set payload
  5. Execute batch
  6. Update job request status

**Error Handling:**

If an error occurs, updates job request status to `Failed` and logs error message.

---

### QueueableJobProcessor

Processor for executing queueable apex jobs.

```apex
public with sharing class QueueableJobProcessor implements IAsyncJobExecutor
```

#### Methods

##### executeJob()

```apex
public void executeJob()
```

Execute the next queueable job in the queue.

- Returns: void
- Logic:
  1. Retrieve next waiting queueable job request
  2. Instantiate job class by name
  3. Set payload
  4. Enqueue job
  5. Update job request status

**Error Handling:**

If an error occurs, updates job request status to `Failed` and logs error message.

---

## Event Handler Classes

### QueueJobEventHandler

Handler for `QUEUE_JOB` events.

```apex
public with sharing class QueueJobEventHandler implements IAsyncJobEventHandler
```

#### Methods

##### handleEvent(AsyncJob__e event)

```apex
public void handleEvent(AsyncJob__e event)
```

Handle queue job event by executing appropriate processor.

- Parameters:
  - `event` (AsyncJob__e): The queue job event
- Returns: void
- Logic: Routes to `BatchableJobProcessor` or `QueueableJobProcessor` based on record type

---

### ChangeStatusJobEventHandler

Handler for `CHANGE_STATUS` events.

```apex
public with sharing class ChangeStatusJobEventHandler implements IAsyncJobEventHandler
```

#### Methods

##### handleEvent(AsyncJob__e event)

```apex
public void handleEvent(AsyncJob__e event)
```

Handle status change event by updating job request.

- Parameters:
  - `event` (AsyncJob__e): The status change event
- Returns: void
- Logic:
  1. Retrieve job request by async job ID
  2. Parse status payload
  3. Update status and timestamps
  4. Persist changes

---

### ErrorJobEventHandler

Handler for `ADD_ERROR` events.

```apex
public with sharing class ErrorJobEventHandler implements IAsyncJobEventHandler
```

#### Methods

##### handleEvent(AsyncJob__e event)

```apex
public void handleEvent(AsyncJob__e event)
```

Handle error event by logging error to job request.

- Parameters:
  - `event` (AsyncJob__e): The error event
- Returns: void
- Logic:
  1. Retrieve job request by async job ID
  2. Append error message from payload
  3. Persist changes

---

## Utility Classes

### AsyncJobRequestSelector

Selector class for querying `AsyncJobRequest__c` records.

```apex
public with sharing class AsyncJobRequestSelector
```

#### Properties

##### instance

```apex
public static AsyncJobRequestSelector instance
```

Singleton instance of the selector.

#### Methods

##### selectById(Id asyncJobRequestId)

```apex
public AsyncJobRequest__c selectById(Id asyncJobRequestId)
```

Query job request by ID.

- Parameters:
  - `asyncJobRequestId` (Id): The job request ID
- Returns: (AsyncJobRequest__c) The job request record
- Throws: QueryException if record not found

##### selectByJobId(Id jobId)

```apex
public AsyncJobRequest__c selectByJobId(Id jobId)
```

Query job request by Salesforce async apex job ID.

- Parameters:
  - `jobId` (Id): The async apex job ID
- Returns: (AsyncJobRequest__c) The job request record
- Throws: QueryException if record not found

##### selectFirstBatchQueueItem()

```apex
public AsyncJobRequest__c selectFirstBatchQueueItem()
```

Get the oldest waiting batch job request.

- Returns: (AsyncJobRequest__c) The first batch job in queue, or null if none exist
- Logic: Queries for `Waiting` status and `Batchable` record type, ordered by creation date

##### selectFirstQueueableQueueItem()

```apex
public AsyncJobRequest__c selectFirstQueueableQueueItem()
```

Get the oldest waiting queueable job request.

- Returns: (AsyncJobRequest__c) The first queueable job in queue, or null if none exist
- Logic: Queries for `Waiting` status and `Queueable` record type, ordered by creation date

##### selectByJobStatus(String jobStatus)

```apex
public List<AsyncJobRequest__c> selectByJobStatus(String jobStatus)
```

Query all job requests by status.

- Parameters:
  - `jobStatus` (String): The job status to filter by
- Returns: (List\<AsyncJobRequest__c\>) Matching job requests, ordered by creation date

---

### AsyncJobRequestDistributor

Utility for distributing and filtering job requests by record type.

```apex
public with sharing class AsyncJobRequestDistributor
```

#### Constructors

##### AsyncJobRequestDistributor(List\<AsyncJobRequest__c\> newJobRequestRecords)

```apex
public AsyncJobRequestDistributor(List<AsyncJobRequest__c> newJobRequestRecords)
```

Create distributor for new job requests.

- Parameters:
  - `newJobRequestRecords` (List\<AsyncJobRequest__c\>): New job request records

##### AsyncJobRequestDistributor(List\<AsyncJobRequest__c\> newJobRequestRecords, Map\<Id, AsyncJobRequest__c\> idToOldJobRequestRecord)

```apex
public AsyncJobRequestDistributor(List<AsyncJobRequest__c> newJobRequestRecords, Map<Id, AsyncJobRequest__c> idToOldJobRequestRecord)
```

Create distributor with old and new values (for trigger contexts).

- Parameters:
  - `newJobRequestRecords` (List\<AsyncJobRequest__c\>): New job request records
  - `idToOldJobRequestRecord` (Map\<Id, AsyncJobRequest__c\>): Map of old values by ID

#### Methods

##### getNewAsyncJobRequests()

```apex
public List<AsyncJobRequest__c> getNewAsyncJobRequests()
```

Get all new job requests.

- Returns: (List\<AsyncJobRequest__c\>) All new records

##### getBatchableAsyncJobRequests()

```apex
public List<AsyncJobRequest__c> getBatchableAsyncJobRequests()
```

Get only batchable job requests.

- Returns: (List\<AsyncJobRequest__c\>) Batchable job requests

##### getQueueableAsyncJobRequests()

```apex
public List<AsyncJobRequest__c> getQueueableAsyncJobRequests()
```

Get only queueable job requests.

- Returns: (List\<AsyncJobRequest__c\>) Queueable job requests

##### getAsyncJobRequestsByRecordTypeId(Id recordTypeId)

```apex
public List<AsyncJobRequest__c> getAsyncJobRequestsByRecordTypeId(Id recordTypeId)
```

Get job requests by specific record type.

- Parameters:
  - `recordTypeId` (Id): The record type ID to filter by
- Returns: (List\<AsyncJobRequest__c\>) Matching job requests

---

## Custom Objects

### AsyncJobRequest__c

Custom object storing async job requests.

#### Fields

- `JobName__c` (Text 255) - Fully qualified Apex class name to execute
- `JobStatus__c` (Picklist) - Current status: Waiting, Pending, Processing, Completed, Failed
- `BatchSize__c` (Number) - Batch size for batch jobs (1-2000)
- `Payload__c` (Long Text Area 131072) - Serialized job parameters (typically JSON)
- `JobId__c` (Text 18) - Salesforce Async Apex Job ID
- `RequestedTime__c` (DateTime) - When job was enqueued
- `ProcessedTime__c` (DateTime) - When job execution started
- `FinishedTime__c` (DateTime) - When job completed or failed
- `ErrorMessage__c` (Long Text Area 131072) - Error details if job failed

#### Record Types

- `Batchable` - For batch apex jobs
- `Queueable` - For queueable apex jobs

---

### AsyncJob__e

Platform Event for job lifecycle communication.

#### Fields

- `Action__c` (Text 255) - Event action: ADD_ERROR, QUEUE_JOB, CHANGE_STATUS
- `AsyncJobId__c` (Text 18) - Salesforce Async Apex Job ID
- `JobRequestId__c` (Text 18) - Related AsyncJobRequest__c ID
- `JobRequestTypeId__c` (Text 18) - Record Type ID of the job request
- `Payload__c` (Long Text Area 131072) - Event-specific payload (JSON)

#### Event Subscriber Configuration

- **Subscriber Name**: AsyncJobEvent
- **Platform Event**: AsyncJob__e
- **Batch Size**: 1
- **Trigger**: AsyncJobEventTrigger

---

## Extension Examples

### Custom Event Handler

```apex
public class CustomActionHandler implements IAsyncJobEventHandler {
    public void handleEvent(AsyncJob__e event) {
        // Custom logic
        System.debug('Custom action triggered: ' + event.Payload__c);
    }
}

// Register in AsyncJobEventService
AsyncJobEventService.instance.setEventHandler(
    AsyncJobEventConstants.Action.CUSTOM_ACTION,
    new CustomActionHandler()
);
```

### Custom Job Executor

```apex
public class CustomJobExecutor implements IAsyncJobExecutor {
    public void executeJob() {
        // Retrieve job from custom source
        CustomJobRequest__c jobRequest = getNextCustomJob();
        
        // Execute custom logic
        processCustomJob(jobRequest);
    }
}
```

---

## Version History

### Version 1.0

Initial release with:
- Batch and Queueable job support
- Event-driven architecture
- Automatic load balancing
- Error handling and logging
- Flex queue management

---

For implementation examples and tutorials, see the [Developer Guide](Developer_Guide.md).