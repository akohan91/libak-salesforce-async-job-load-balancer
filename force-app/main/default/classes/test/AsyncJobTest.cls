@IsTest
private class AsyncJobTest {
	
	private static final String TEST_PAYLOAD = '{"data":"test value"}';
	private static final String MOCK_JOB_ID = new FakeId(AsyncApexJob.sObjectType).getFakeId();
	
	/**
	 * Test implementation of AsyncJob for testing purposes
	 */
	private class TestAsyncJob extends AsyncJob {
		public String getPayload() {
			return this.jobPayload;
		}
	}
	
	@IsTest
	static void testWithPayload() {
		TestAsyncJob job = new TestAsyncJob();
		
		Test.startTest();
		AsyncJob returnedJob = job.withPayload(TEST_PAYLOAD);
		Test.stopTest();
		
		Assert.areEqual(TEST_PAYLOAD, job.getPayload(), 'Payload should be set correctly');
		Assert.areEqual(job, returnedJob, 'Method should return the instance for method chaining');
	}
	
	@IsTest
	static void testCreateJobErrorEvent() {
		TestAsyncJob job = new TestAsyncJob();
		Exception testException = new IllegalArgumentException('Test exception message');
		
		Test.startTest();
		AsyncJob__e errorEvent = job.createJobErrorEvent(testException, MOCK_JOB_ID);
		Test.stopTest();
		
		Assert.areEqual(AsyncJobEventConstants.Action.ADD_ERROR.name(), errorEvent.Action__c, 
			'Action should be ADD_ERROR');
		Assert.areEqual(MOCK_JOB_ID, errorEvent.AsyncJobId__c, 
			'Job ID should be set correctly');
		Assert.isTrue(errorEvent.Payload__c.contains('Test exception message'), 
			'Error message should contain the exception message');
		Assert.isTrue(errorEvent.Payload__c.contains('Stack Trace'), 
			'Error message should contain the stack trace');
	}
	
	@IsTest
	static void testCreateJobChangeStatusEvent() {
		TestAsyncJob job = new TestAsyncJob();
		AsyncJobRequestConstants.JobStatus testStatus = AsyncJobRequestConstants.JobStatus.Processing;
		
		Test.startTest();
		AsyncJob__e statusEvent = job.createJobChangeStatusEvent(testStatus, MOCK_JOB_ID);
		Test.stopTest();
		
		Assert.areEqual(AsyncJobEventConstants.Action.CHANGE_STATUS.name(), statusEvent.Action__c, 
			'Action should be CHANGE_STATUS');
		Assert.areEqual(MOCK_JOB_ID, statusEvent.AsyncJobId__c, 
			'Job ID should be set correctly');
		
		AsyncJob.ChangeStatusPayload payload = (AsyncJob.ChangeStatusPayload)JSON.deserialize(
			statusEvent.Payload__c,
			AsyncJob.ChangeStatusPayload.class
		);
		Assert.areEqual(testStatus, payload.status, 
			'Status in payload should match the provided status');
		Assert.isNotNull(payload.changedDatetime, 
			'Changed datetime should be set');
	}
	
	@IsTest
	static void testChangeStatusPayloadSerialization() {
		AsyncJobRequestConstants.JobStatus testStatus = AsyncJobRequestConstants.JobStatus.Completed;
		Datetime testTime = Datetime.now();
		AsyncJob.ChangeStatusPayload payload = new AsyncJob.ChangeStatusPayload(testStatus, testTime);
		
		Test.startTest();
		String jsonResult = payload.json();
		AsyncJob.ChangeStatusPayload deserializedPayload = (AsyncJob.ChangeStatusPayload)JSON.deserialize(
			jsonResult,
			AsyncJob.ChangeStatusPayload.class
		);
		Test.stopTest();
		
		Assert.areEqual(testStatus, deserializedPayload.status, 
			'Status should be preserved after serialization/deserialization');
		Assert.isTrue(Math.abs(testTime.getTime() - deserializedPayload.changedDatetime.getTime()) < 1000, 
			'Datetime should be preserved with minimal difference after serialization/deserialization');
	}
	
	@IsTest
	static void testMultipleStatusChanges() {
		TestAsyncJob job = new TestAsyncJob();
		
		Test.startTest();
		AsyncJob__e pendingEvent = job.createJobChangeStatusEvent(AsyncJobRequestConstants.JobStatus.Pending, MOCK_JOB_ID);
		AsyncJob__e processingEvent = job.createJobChangeStatusEvent(AsyncJobRequestConstants.JobStatus.Processing, MOCK_JOB_ID);
		AsyncJob__e completedEvent = job.createJobChangeStatusEvent(AsyncJobRequestConstants.JobStatus.Completed, MOCK_JOB_ID);
		Test.stopTest();
		
		AsyncJob.ChangeStatusPayload pendingPayload = (AsyncJob.ChangeStatusPayload)JSON.deserialize(
			pendingEvent.Payload__c,
			AsyncJob.ChangeStatusPayload.class
		);
		Assert.areEqual(AsyncJobRequestConstants.JobStatus.Pending, pendingPayload.status,
			'Pending event should have Pending status');
			
		AsyncJob.ChangeStatusPayload processingPayload = (AsyncJob.ChangeStatusPayload)JSON.deserialize(
			processingEvent.Payload__c,
			AsyncJob.ChangeStatusPayload.class
		);
		Assert.areEqual(AsyncJobRequestConstants.JobStatus.Processing, processingPayload.status,
			'Processing event should have Processing status');
			
		AsyncJob.ChangeStatusPayload completedPayload = (AsyncJob.ChangeStatusPayload)JSON.deserialize(
			completedEvent.Payload__c,
			AsyncJob.ChangeStatusPayload.class
		);
		Assert.areEqual(AsyncJobRequestConstants.JobStatus.Completed, completedPayload.status,
			'Completed event should have Completed status');
	}
}
