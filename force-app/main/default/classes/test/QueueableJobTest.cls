@isTest
public with sharing class QueueableJobTest {
	
	/**
	 * Mock implementation of QueueableContext for testing
	 */
	private class MockQueueableContext implements System.QueueableContext {
		private Id jobId;
		
		public MockQueueableContext(Id jobId) {
			this.jobId = jobId;
		}
		
		public Id getJobId() {
			return this.jobId;
		}
	}
	
	/**
	 * Mock implementation of FinalizerContext for testing
	 */
	private class MockFinalizerContext implements System.FinalizerContext {
		private Id asyncApexJobId;
		private System.ParentJobResult result;
		private Exception exc;
		
		public MockFinalizerContext(Id asyncApexJobId, System.ParentJobResult result, Exception exc) {
			this.asyncApexJobId = asyncApexJobId;
			this.result = result;
			this.exc = exc;
		}
		
		public Id getAsyncApexJobId() {
			return this.asyncApexJobId;
		}
		
		public System.ParentJobResult getResult() {
			return this.result;
		}
		
		public Exception getException() {
			return this.exc;
		}
		
		public String getRequestId() {
			return null;
		}
	}

	@TestSetup
	static void makeData(){
		AsyncJobRequestService.instance.setBypass();
		insert new AsyncJobRequest__c(
			RecordTypeId = AsyncJobRequestConstants.recordType.QueueableId,
			JobName__c = MockQueueableJob.class.getName(),
			JobId__c = new FakeId(AsyncApexJob.sObjectType).getFakeId()
		);
	}
	
	@IsTest
	static void testExecuteMethodSuccess() {
		List<AsyncJobRequest__c> jobRequests = AsyncJobRequestSelector.instance.getByJobStatus(
			AsyncJobRequestConstants.JobStatus.Waiting.name()
		);
		Assert.areEqual(1, jobRequests.size(), 'Should have exactly one job request in Waiting status');
		MockQueueableJob job = new MockQueueableJob();
		MockQueueableContext mockContext = new MockQueueableContext(jobRequests.get(0).JobId__c);
		
		Test.startTest();

		job.execute(mockContext);
		Test.getEventBus().deliver();
		
		Test.stopTest();
		
		Assert.isTrue(job.executeCalled, 'doExecute should be called');
		AsyncJobRequest__c jobRequest = AsyncJobRequestSelector.instance.getByJobId(
			jobRequests.get(0).JobId__c
		);
		Assert.areEqual(AsyncJobRequestConstants.JobStatus.Processing.name(), jobRequest.JobStatus__c, 'Job status should be Processing after execution');
	}
	
	@IsTest
	static void testFinalizerContextWithSuccess() {
		List<AsyncJobRequest__c> jobRequests = AsyncJobRequestSelector.instance.getByJobStatus(
			AsyncJobRequestConstants.JobStatus.Waiting.name()
		);
		Assert.areEqual(1, jobRequests.size(), 'Should have exactly one job request in Waiting status');
		MockQueueableJob job = new MockQueueableJob();
		MockFinalizerContext mockContext = new MockFinalizerContext(
			jobRequests.get(0).JobId__c,
			System.ParentJobResult.SUCCESS,
			null
		);
		
		Test.startTest();

		job.execute(mockContext);
		Test.getEventBus().deliver();
		
		Test.stopTest();

		AsyncJobRequest__c jobRequest = AsyncJobRequestSelector.instance.getByJobId(
			jobRequests.get(0).JobId__c
		);
		Assert.areEqual(AsyncJobRequestConstants.JobStatus.Completed.name(), jobRequest.JobStatus__c, 'Job status should be Completed after finalizer success');
		Assert.isNull(jobRequest.ErrorMessage__c, 'ErrorMessage should be null for successful finalizer');
	}
	
	@IsTest
	static void testFinalizerContextWithException() {
		List<AsyncJobRequest__c> jobRequests = AsyncJobRequestSelector.instance.getByJobStatus(
			AsyncJobRequestConstants.JobStatus.Waiting.name()
		);
		Assert.areEqual(1, jobRequests.size(), 'Should have exactly one job request in Waiting status');
		MockQueueableJob job = new MockQueueableJob();
		Exception testException = new IllegalArgumentException('Test exception message');
		
		MockFinalizerContext mockContext = new MockFinalizerContext(
			jobRequests.get(0).JobId__c,
			System.ParentJobResult.UNHANDLED_EXCEPTION,
			testException
		);
		
		Test.startTest();

		job.execute(mockContext);
		Test.getEventBus().deliver();
		
		Test.stopTest();

		AsyncJobRequest__c jobRequest = AsyncJobRequestSelector.instance.getByJobId(
			jobRequests.get(0).JobId__c
		);
		Assert.isNotNull(jobRequest.ErrorMessage__c, 'ErrorMessage should not be null when exception occurs');
		Assert.isTrue(jobRequest.ErrorMessage__c.contains(testException.getMessage()), 'ErrorMessage should contain the exception message');
	}
}