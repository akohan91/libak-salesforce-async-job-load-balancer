@IsTest
public with sharing class AsyncJobRequestServiceTest {
	
	/**
	 * Custom exception class for testing platform events
	 */
	private class EventPublishException extends Exception {}
	
	@IsTest
	static void testSingletonPattern() {
		AsyncJobRequestService instance1 = AsyncJobRequestService.instance;
		AsyncJobRequestService instance2 = AsyncJobRequestService.instance;
		
		Assert.isNotNull(instance1, 'Instance should not be null');
		Assert.areEqual(instance1, instance2, 'Both references should point to the same instance');
	}
	
	@IsTest
	static void testPublishQueueJobEvents() {
		List<AsyncJobRequest__c> jobRequests = new List<AsyncJobRequest__c>{
			new AsyncJobRequest__c(
				RecordTypeId = AsyncJobRequestConstants.recordType.BatchableId,
				JobName__c = 'TestBatchableJob',
				JobStatus__c = AsyncJobRequestConstants.JobStatus.Waiting.name()
			), new AsyncJobRequest__c(
				RecordTypeId = AsyncJobRequestConstants.recordType.QueueableId,
				JobName__c = 'TestQueueableJob',
				JobStatus__c = AsyncJobRequestConstants.JobStatus.Waiting.name()
			)
		};
		AsyncJobRequestService.instance.setBypass();
		insert jobRequests;

		Test.startTest();

		AsyncJobRequestService.instance.unsetBypass();
		List<Database.SaveResult> results = AsyncJobRequestService.instance.publishQueueJobEvents(jobRequests);
		Test.getEventBus().deliver();
		
		Test.stopTest();
		
		Assert.isTrue(!results.isEmpty(), 'Events should have been published');
		Assert.areEqual(2, results.size(), 'Two events should have been published');
		
		for (Database.SaveResult result : results) {
			Assert.isTrue(result.isSuccess(), 'Event publishing should be successful');
		}
	}
	
	@IsTest
	static void testBypassMode() {
		AsyncJobRequest__c jobRequest = new AsyncJobRequest__c(
			RecordTypeId = AsyncJobRequestConstants.recordType.BatchableId,
			JobName__c = 'TestBatchableJob',
			JobStatus__c = AsyncJobRequestConstants.JobStatus.Waiting.name()
		);
		
		insert jobRequest;
		
		Test.startTest();

		AsyncJobRequestService.instance.setBypass();
		List<Database.SaveResult> bypassResults = AsyncJobRequestService.instance.publishQueueJobEvents(
			new List<AsyncJobRequest__c>{jobRequest}
		);
		
		AsyncJobRequestService.instance.unsetBypass();
		List<Database.SaveResult> nonBypassResults = AsyncJobRequestService.instance.publishQueueJobEvents(
			new List<AsyncJobRequest__c>{jobRequest}
		);
		
		Test.getEventBus().deliver();
		
		Test.stopTest();
		
		Assert.areEqual(0, bypassResults.size(), 'No events should be published when bypass is active');
		Assert.areEqual(1, nonBypassResults.size(), 'Events should be published after bypass is disabled');
		
		if (!nonBypassResults.isEmpty()) {
			Assert.isTrue(nonBypassResults[0].isSuccess(), 'Event publishing should be successful when bypass is off');
		}
	}
	
	@IsTest
	static void testEmptyJobRequestsList() {
		List<AsyncJobRequest__c> emptyList = new List<AsyncJobRequest__c>();
		
		Test.startTest();

		AsyncJobRequestService.instance.unsetBypass();
		List<Database.SaveResult> results = AsyncJobRequestService.instance.publishQueueJobEvents(emptyList);
		Test.getEventBus().deliver();
		
		Test.stopTest();
		
		Assert.areEqual(0, results.size(), 'No events should be published for empty job request list');
	}
}