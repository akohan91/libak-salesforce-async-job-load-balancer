@IsTest
public with sharing class ErrorJobEventHandlerTest {
	
	@TestSetup
	static void makeData() {
		AsyncJobRequestService.instance.setBypass();
		insert new AsyncJobRequest__c(
			RecordTypeId = AsyncJobRequestConstants.recordType.BatchableId,
			JobName__c = 'TestBatchJob',
			JobId__c = new FakeId(AsyncApexJob.SObjectType).getFakeId(),
			BatchSize__c = 200,
			JobStatus__c = AsyncJobRequestConstants.JobStatus.Waiting.name()
		);
	}
	
	@IsTest
	static void testHandleErrorEvent() {
		AsyncJobRequest__c jobRequest = AsyncJobRequestSelector.instance.getByJobStatus(
			AsyncJobRequestConstants.JobStatus.Waiting.name()
		).get(0);
		Assert.isNull(jobRequest.ErrorMessage__c, 'Error message should be null initially');
		
		String errorPayload = 'Test error message';
		AsyncJob__e errorEvent = new AsyncJob__e(
			Action__c = AsyncJobEventConstants.Action.ADD_ERROR.name(),
			AsyncJobId__c = jobRequest.JobId__c,
			Payload__c = errorPayload
		);
		
		Test.startTest();
		new ErrorJobEventHandler().handleEvent(errorEvent);
		Test.stopTest();
		
		jobRequest = AsyncJobRequestSelector.instance.getById(jobRequest.Id);
		
		Assert.areEqual(errorPayload, jobRequest.ErrorMessage__c, 'Error message should be updated');
	}
	
	@IsTest
	static void testHandleMultipleErrorEvents() {
		AsyncJobRequest__c jobRequest = AsyncJobRequestSelector.instance.getByJobStatus(
			AsyncJobRequestConstants.JobStatus.Waiting.name()
		).get(0);
		
		String firstErrorPayload = 'First error message';
		AsyncJob__e firstErrorEvent = new AsyncJob__e(
			Action__c = AsyncJobEventConstants.Action.ADD_ERROR.name(),
			AsyncJobId__c = jobRequest.JobId__c,
			Payload__c = firstErrorPayload
		);
		
		String secondErrorPayload = 'Second error message';
		AsyncJob__e secondErrorEvent = new AsyncJob__e(
			Action__c = AsyncJobEventConstants.Action.ADD_ERROR.name(),
			AsyncJobId__c = jobRequest.JobId__c,
			Payload__c = secondErrorPayload
		);
		
		Test.startTest();
		new ErrorJobEventHandler().handleEvent(firstErrorEvent);
		
		new ErrorJobEventHandler().handleEvent(secondErrorEvent);
		Test.stopTest();
		
		jobRequest = AsyncJobRequestSelector.instance.getById(jobRequest.Id);
		Assert.isTrue(jobRequest.ErrorMessage__c.contains(firstErrorPayload), 'Error message should contain first error');
		Assert.isTrue(jobRequest.ErrorMessage__c.contains(secondErrorPayload), 'Error message should contain second error');
	}
}