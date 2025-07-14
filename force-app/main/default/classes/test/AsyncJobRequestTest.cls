@IsTest
private class AsyncJobRequestTest {
	
	private static final String TEST_JOB_ID = new FakeId(AsyncApexJob.sObjectType).getFakeId();
	
	@IsTest
	static void testConstructor() {
		AsyncJobRequest__c record = createTestRecord();
		
		Test.startTest();
		AsyncJobRequest wrapper = new AsyncJobRequest(record);
		Test.stopTest();
		
		Assert.areEqual(record, wrapper.record(), 'The wrapper should return the same record that was passed in');
	}
	
	@IsTest
	static void testSetJobId() {
		AsyncJobRequest__c record = createTestRecord();
		AsyncJobRequest wrapper = new AsyncJobRequest(record);
		
		Test.startTest();
		AsyncJobRequest returnedWrapper = wrapper.setJobId(TEST_JOB_ID);
		Test.stopTest();
		
		Assert.areEqual(TEST_JOB_ID, wrapper.record().JobId__c, 'JobId__c should be set to test ID');
		Assert.areEqual(wrapper, returnedWrapper, 'Method should return the instance for method chaining');
	}
	
	@IsTest
	static void testSetJobStatusPending() {
		testSetJobStatus(AsyncJobRequestConstants.JobStatus.Pending, 'RequestedTime__c');
	}
	
	@IsTest
	static void testSetJobStatusProcessing() {
		testSetJobStatus(AsyncJobRequestConstants.JobStatus.Processing, 'ProcessedTime__c');
	}
	
	@IsTest
	static void testSetJobStatusCompleted() {
		testSetJobStatus(AsyncJobRequestConstants.JobStatus.Completed, 'FinishedTime__c');
	}
	
	private static void testSetJobStatus(AsyncJobRequestConstants.JobStatus status, String dateTimeField) {
		AsyncJobRequest__c record = createTestRecord();
		AsyncJobRequest wrapper = new AsyncJobRequest(record);
		
		Datetime testTime = Datetime.now();
		AsyncJob.ChangeStatusPayload payload = new AsyncJob.ChangeStatusPayload(status, testTime);
		
		Test.startTest();
		AsyncJobRequest returnedWrapper = wrapper.setJobStatus(payload);
		Test.stopTest();
		
		Assert.areEqual(status.name(), wrapper.record().JobStatus__c, 'JobStatus__c should be updated');
		
		Datetime fieldValue = (Datetime)wrapper.record().get(dateTimeField);
		Assert.areEqual(testTime, fieldValue, dateTimeField + ' should be set to test time');
		
		Assert.areEqual(wrapper, returnedWrapper, 'Method should return the instance for method chaining');
	}
	
	@IsTest
	static void testAddErrorMessageException() {
		AsyncJobRequest__c record = createTestRecord();
		AsyncJobRequest wrapper = new AsyncJobRequest(record);
		
		Exception testException = new IllegalArgumentException('Test exception message');
		
		Test.startTest();
		AsyncJobRequest returnedWrapper = wrapper.addErrorMessage(testException);
		Test.stopTest();
		
		Assert.isTrue(wrapper.record().ErrorMessage__c.contains('Test exception message'), 
			'Error message should contain exception message');
		Assert.isTrue(wrapper.record().ErrorMessage__c.contains('Stack Trace'), 
			'Error message should contain stack trace');
		Assert.areEqual(wrapper, returnedWrapper, 'Method should return the instance for method chaining');
	}
	
	@IsTest
	static void testAddErrorMessageString() {
		AsyncJobRequest__c record = createTestRecord();
		AsyncJobRequest wrapper = new AsyncJobRequest(record);
		String testError = 'Test error message';
		
		Test.startTest();
		AsyncJobRequest returnedWrapper = wrapper.addErrorMessage(testError);
		Test.stopTest();
		
		Assert.areEqual(testError, wrapper.record().ErrorMessage__c, 'Error message should be set');
		Assert.areEqual(wrapper, returnedWrapper, 'Method should return the instance for method chaining');
	}
	
	@IsTest
	static void testAddMultipleErrorMessages() {
		AsyncJobRequest__c record = createTestRecord();
		AsyncJobRequest wrapper = new AsyncJobRequest(record);
		String firstError = 'First error';
		String secondError = 'Second error';
		
		Test.startTest();
		wrapper.addErrorMessage(firstError);
		wrapper.addErrorMessage(secondError);
		Test.stopTest();
		
		Assert.isTrue(wrapper.record().ErrorMessage__c.contains(firstError), 'Error should contain first message');
		Assert.isTrue(wrapper.record().ErrorMessage__c.contains(secondError), 'Error should contain second message');
	}
	
	private static AsyncJobRequest__c createTestRecord() {
		return new AsyncJobRequest__c(
			JobName__c = 'Test Job',
			JobStatus__c = AsyncJobRequestConstants.JobStatus.Waiting.name()
		);
	}
}
