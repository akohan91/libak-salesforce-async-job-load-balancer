@IsTest
public with sharing class BatchJobProcessorTest {
	
	@TestSetup
	static void makeData(){
		AsyncJobRequestService.instance.setBypass();

		insert new AsyncJobRequest__c(
			RecordTypeId = AsyncJobRequestConstants.recordType.BatchableId,
			JobName__c = MockBatchableJob.class.getName(),
			BatchSize__c = 200
		);
	}

	@IsTest
	static void testExecuteJobPositive(){

		List<AsyncJobRequest__c> jobRequests = AsyncJobRequestSelector.instance.getByJobStatus(
			AsyncJobRequestConstants.JobStatus.Pending.name()
		);
		Assert.areEqual(0, jobRequests.size(), 'There should not be any Async Job Requests in status Pending.');

		Test.startTest();

		new BatchJobProcessor().executeJob();
		jobRequests = AsyncJobRequestSelector.instance.getByJobStatus(
			AsyncJobRequestConstants.JobStatus.Pending.name()
		);

		Test.stopTest();
		
		Assert.areEqual(1, jobRequests.size(), 'There should be a Async Job Requests in status Pending.');
		Assert.isNotNull(jobRequests.get(0).JobId__c, 'The Job Id field has to be specified.');
	}

	@IsTest
	static void testExecuteJobNegative(){
		List<AsyncJobRequest__c> jobRequests = AsyncJobRequestSelector.instance.getByJobStatus(
			AsyncJobRequestConstants.JobStatus.Waiting.name()
		);
		jobRequests.get(0).JobName__c = 'IncorrectJobName';
		AsyncJobRequestService.instance.setBypass();
		update jobRequests;

		jobRequests = AsyncJobRequestSelector.instance.getByJobStatus(
			AsyncJobRequestConstants.JobStatus.Failed.name()
		);
		Assert.areEqual(0, jobRequests.size(), 'There should not be any Async Job Requests in status Failed.');

		Test.startTest();

		new BatchJobProcessor().executeJob();
		jobRequests = AsyncJobRequestSelector.instance.getByJobStatus(
			AsyncJobRequestConstants.JobStatus.Failed.name()
		);

		Test.stopTest();
		
		Assert.areEqual(1, jobRequests.size(), 'There should be a Async Job Requests in status Failed.');
		Assert.isNull(jobRequests.get(0).JobId__c, 'The Job Id field has to be specified.');
		Assert.isNotNull(jobRequests.get(0).ErrorMessage__c, 'The Error Message field has to be specified.');
	}
}