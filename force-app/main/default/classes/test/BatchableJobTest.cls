@IsTest
private class BatchableJobTest {

	/**
	 * Test implementation of BatchableJob for testing
	 */
	private class TestBatchableJob extends BatchableJob {
		public Boolean startCalled = false;
		public Boolean executeCalled = false;
		public Boolean finishCalled = false;
		public Exception startException;
		public Exception executeException;
		public Exception finishException;
		
		protected override Database.QueryLocator doStart(Database.BatchableContext bc) {
			Test.getEventBus().deliver();
			startCalled = true;
			if (startException != null) {
				throw startException;
			}
			return Database.getQueryLocator('SELECT Id FROM User LIMIT 1');
		}
		
		protected override void doExecute(Database.BatchableContext bc, List<SObject> scope) {
			executeCalled = true;
			if (executeException != null) {
				throw executeException;
			}
		}
		
		protected override void doFinish(Database.BatchableContext bc) {
			finishCalled = true;
			if (finishException != null) {
				throw finishException;
			}
		}
	}
	
	/**
	 * Mock implementation of BatchableContext for testing
	 */
	private class MockBatchableContext implements Database.BatchableContext {
		private Id jobId;
		
		public MockBatchableContext(Id jobId) {
			this.jobId = jobId;
		}
		
		public Id getJobId() {
			return this.jobId;
		}
		
		public Id getChildJobId() {
			return null;
		}
	}

	@TestSetup
	static void makeData(){
		AsyncJobRequestService.instance.setBypass();
		insert new AsyncJobRequest__c(
			RecordTypeId = AsyncJobRequestConstants.recordType.BatchableId,
			JobName__c = TestBatchableJob.class.getName(),
			JobId__c = new FakeId(AsyncApexJob.sObjectType).getFakeId(),
			BatchSize__c = 200
		);
	}

	
	@IsTest
	static void testStartMethodSuccess() {
		List<AsyncJobRequest__c> jobRequests = AsyncJobRequestSelector.instance.getByJobStatus(
			AsyncJobRequestConstants.JobStatus.Waiting.name()
		);
		Assert.areEqual(1, jobRequests.size(), 'Should have exactly one job request in Waiting status');
		TestBatchableJob job = new TestBatchableJob();
		MockBatchableContext mockContext = new MockBatchableContext(jobRequests.get(0).JobId__c);
		
		Test.startTest();

		Database.QueryLocator result = job.start(mockContext);
		Test.getEventBus().deliver();
		
		Test.stopTest();
		
		Assert.isTrue(job.startCalled, 'doStart should be called');
		Assert.isNotNull(result, 'QueryLocator should be returned');
		AsyncJobRequest__c jobRequest = AsyncJobRequestSelector.instance.getByJobId(
			jobRequests.get(0).JobId__c
		);
		Assert.areEqual(AsyncJobRequestConstants.JobStatus.Processing.name(), jobRequest.JobStatus__c, 'Job status should be Processing after execution');
	}
	
	@IsTest
	static void testStartMethodException() {
		List<AsyncJobRequest__c> jobRequests = AsyncJobRequestSelector.instance.getByJobStatus(
			AsyncJobRequestConstants.JobStatus.Waiting.name()
		);
		Assert.areEqual(1, jobRequests.size(), 'Should have exactly one job request in Waiting status');
		TestBatchableJob job = new TestBatchableJob();
		job.startException = new IllegalArgumentException('Test exception message');
		MockBatchableContext mockContext = new MockBatchableContext(jobRequests.get(0).JobId__c);
		
		Test.startTest();
		
		try {
			job.start(mockContext);
			Assert.fail('Exception should have been thrown in job.start');
		} catch (Exception e) {
			Assert.isTrue(job.startCalled, 'doStart should be called');
		}

		Test.getEventBus().deliver();
		
		Test.stopTest();
		
		AsyncJobRequest__c jobRequest = AsyncJobRequestSelector.instance.getByJobId(
			jobRequests.get(0).JobId__c
		);
		Assert.isNotNull(jobRequest.ErrorMessage__c, 'ErrorMessage should not be null when exception occurs');
		Assert.isTrue(jobRequest.ErrorMessage__c.contains(job.startException.getMessage()), 'ErrorMessage should contain the exception message');
	}
	
	@IsTest
	static void testExecuteMethodSuccess() {
		TestBatchableJob job = new TestBatchableJob();
		MockBatchableContext mockContext = new MockBatchableContext(null);
		List<SObject> scope = new List<SObject>{ new User(Id = UserInfo.getUserId()) };
		
		Test.startTest();

		job.execute(mockContext, scope);
		
		Test.stopTest();
		
		Assert.isTrue(job.executeCalled, 'doExecute should be called');
	}
	
	@IsTest
	static void testExecuteMethodException() {
		List<AsyncJobRequest__c> jobRequests = AsyncJobRequestSelector.instance.getByJobStatus(
			AsyncJobRequestConstants.JobStatus.Waiting.name()
		);
		Assert.areEqual(1, jobRequests.size(), 'Should have exactly one job request in Waiting status');
		TestBatchableJob job = new TestBatchableJob();
		job.executeException = new IllegalArgumentException('Test exception message');
		MockBatchableContext mockContext = new MockBatchableContext(jobRequests.get(0).JobId__c);
		List<SObject> scope = new List<SObject>{ new User(Id = UserInfo.getUserId()) };
		
		Test.startTest();

		try {
			job.execute(mockContext, scope);
			Assert.fail('Exception should have been thrown job.execute');
		} catch (Exception e) {
			Assert.isTrue(job.executeCalled, 'doExecute should be called');
		}
		
		Test.getEventBus().deliver();
		
		Test.stopTest();
		
		AsyncJobRequest__c jobRequest = AsyncJobRequestSelector.instance.getByJobId(
			jobRequests.get(0).JobId__c
		);
		Assert.isNotNull(jobRequest.ErrorMessage__c, 'ErrorMessage should not be null when exception occurs');
		Assert.isTrue(jobRequest.ErrorMessage__c.contains(job.executeException.getMessage()), 'ErrorMessage should contain the exception message');
	}
	
	@IsTest
	static void testFinishMethodSuccess() {
		List<AsyncJobRequest__c> jobRequests = AsyncJobRequestSelector.instance.getByJobStatus(
			AsyncJobRequestConstants.JobStatus.Waiting.name()
		);
		Assert.areEqual(1, jobRequests.size(), 'Should have exactly one job request in Waiting status');
		TestBatchableJob job = new TestBatchableJob();
		MockBatchableContext mockContext = new MockBatchableContext(jobRequests.get(0).JobId__c);
		
		Test.startTest();

		job.finish(mockContext);
		Test.getEventBus().deliver();
		
		Test.stopTest();
		
		Assert.isTrue(job.finishCalled, 'doFinish should be called');
		AsyncJobRequest__c jobRequest = AsyncJobRequestSelector.instance.getByJobId(
			jobRequests.get(0).JobId__c
		);
		Assert.areEqual(AsyncJobRequestConstants.JobStatus.Completed.name(), jobRequest.JobStatus__c, 'Job status should be Completed after execution');
	}


	@IsTest
	static void testFinishMethodException() {
		List<AsyncJobRequest__c> jobRequests = AsyncJobRequestSelector.instance.getByJobStatus(
			AsyncJobRequestConstants.JobStatus.Waiting.name()
		);
		Assert.areEqual(1, jobRequests.size(), 'Should have exactly one job request in Waiting status');
		TestBatchableJob job = new TestBatchableJob();
		job.finishException = new IllegalArgumentException('Test exception message');
		MockBatchableContext mockContext = new MockBatchableContext(jobRequests.get(0).JobId__c);
		
		Test.startTest();

		try {
			job.finish(mockContext);
			Assert.fail('Exception should have been thrown job.finish');
		} catch (Exception e) {
			Assert.isTrue(job.finishCalled, 'doExecute should be called');
		}
		
		Test.getEventBus().deliver();
		
		Test.stopTest();
		
		AsyncJobRequest__c jobRequest = AsyncJobRequestSelector.instance.getByJobId(
			jobRequests.get(0).JobId__c
		);
		Assert.isNotNull(jobRequest.ErrorMessage__c, 'ErrorMessage should not be null when exception occurs');
		Assert.isTrue(jobRequest.ErrorMessage__c.contains(job.finishException.getMessage()), 'ErrorMessage should contain the exception message');
	}
}