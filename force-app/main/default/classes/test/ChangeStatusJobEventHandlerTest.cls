@IsTest
public with sharing class ChangeStatusJobEventHandlerTest {

	@TestSetup
	static void makeData() {
		AsyncJobRequestService.instance.setBypass();
		insert new AsyncJobRequest__c(
			RecordTypeId = AsyncJobRequestConstants.recordType.BatchableId,
			JobName__c = BatchJobProcessorTestBatchableJob.class.getName(),
			JobId__c = new FakeId(AsyncApexJob.sObjectType).getFakeId(),
			BatchSize__c = 200
		);
	}

	@IsTest
	static void testHandleChangeStatusEventNotFinalStatus() {
		List<AsyncJobRequest__c> jobRequests = AsyncJobRequestSelector.instance.getByJobStatus(
			AsyncJobRequestConstants.JobStatus.Waiting.name()
		);
		Assert.areEqual(1, jobRequests.size(), 'There should be one Async Job Request in status Waiting.');

		Test.startTest();

		new ChangeStatusJobEventHandler().handleEvent(
			new AsyncJob().createJobChangeStatusEvent(
				AsyncJobRequestConstants.JobStatus.Processing,
				jobRequests.get(0).JobId__c
			)
		);

		Test.stopTest();

		jobRequests = AsyncJobRequestSelector.instance.getByJobStatus(
			AsyncJobRequestConstants.JobStatus.Processing.name()
		);

		Assert.areEqual(1, jobRequests.size(), 'There should be one Async Job Request in status Processing.');
		Assert.isNotNull(jobRequests.get(0).JobId__c, 'The Job Id field should not be null.');
	}

	@IsTest
	static void testHandleChangeStatusEventFinalStatus() {
		AsyncJobRequestService.instance.setBypass();
		insert new AsyncJobRequest__c(
			RecordTypeId = AsyncJobRequestConstants.recordType.BatchableId,
			JobName__c = BatchJobProcessorTestBatchableJob.class.getName(),
			JobId__c = new FakeId(AsyncApexJob.sObjectType).getFakeId(),
			BatchSize__c = 200
		);

		List<AsyncJobRequest__c> jobRequests = AsyncJobRequestSelector.instance.getByJobStatus(
			AsyncJobRequestConstants.JobStatus.Waiting.name()
		);
		Assert.areEqual(2, jobRequests.size(), 'There should be two Async Job Requests in status Waiting.');

		Test.startTest();

		new ChangeStatusJobEventHandler().handleEvent(
			new AsyncJob().createJobChangeStatusEvent(
				AsyncJobRequestConstants.JobStatus.Completed,
				jobRequests.get(0).JobId__c
			)
		);

		Test.stopTest();

		jobRequests = AsyncJobRequestSelector.instance.getByJobStatus(
			AsyncJobRequestConstants.JobStatus.Waiting.name()
		);

		Assert.areEqual(0, jobRequests.size(), 'There should be no Async Job Requests in status Waiting.');
	}
}