@IsTest
private class AsyncJobRequestDistributorTest {
	
	@IsTest
	static void testConstructorWithNewRecordsOnly() {
		List<AsyncJobRequest__c> mockRecords = createMockJobRequests();
		
		Test.startTest();
		AsyncJobRequestDistributor distributor = new AsyncJobRequestDistributor(mockRecords);
		Test.stopTest();
		
		Assert.areEqual(mockRecords, distributor.getNewAsyncJobRequests(), 
			'The distributor should return the same list of records passed to the constructor');
	}
	
	@IsTest
	static void testConstructorWithOldRecordsMap() {
		List<AsyncJobRequest__c> mockRecords = createMockJobRequests();
		Map<Id, AsyncJobRequest__c> oldRecordsMap = new Map<Id, AsyncJobRequest__c>();
		
		for (AsyncJobRequest__c jobRequest : mockRecords) {
			oldRecordsMap.put(jobRequest.RecordTypeId, mockRecords[0]);
		}
		
		Test.startTest();
		AsyncJobRequestDistributor distributor = new AsyncJobRequestDistributor(mockRecords, oldRecordsMap);
		Test.stopTest();
		
		Assert.areEqual(mockRecords, distributor.getNewAsyncJobRequests(), 
			'The distributor should return the same list of records passed to the constructor');
	}
	
	@IsTest
	static void testGetBatchableAsyncJobRequests() {
		List<AsyncJobRequest__c> mockRecords = createMockJobRequests();
		AsyncJobRequestDistributor distributor = new AsyncJobRequestDistributor(mockRecords);
		
		Test.startTest();
		List<AsyncJobRequest__c> batchableRequests = distributor.getBatchableAsyncJobRequests();
		Test.stopTest();
		
		Assert.areEqual(3, batchableRequests.size(), 'Should return all batch job requests');
		for(AsyncJobRequest__c request : batchableRequests) {
			Assert.areEqual(AsyncJobRequestConstants.recordType.BatchableId, request.RecordTypeId, 
				'All returned records should have the batch record type ID');
		}
	}
	
	@IsTest
	static void testGetQueueableAsyncJobRequests() {
		List<AsyncJobRequest__c> mockRecords = createMockJobRequests();
		AsyncJobRequestDistributor distributor = new AsyncJobRequestDistributor(mockRecords);
		
		Test.startTest();
		List<AsyncJobRequest__c> queueableRequests = distributor.getQueueableAsyncJobRequests();
		Test.stopTest();
		
		Assert.areEqual(2, queueableRequests.size(), 'Should return all queueable job requests');
		for(AsyncJobRequest__c request : queueableRequests) {
			Assert.areEqual(AsyncJobRequestConstants.recordType.QueueableId, request.RecordTypeId, 
				'All returned records should have the queueable record type ID');
		}
	}
	
	@IsTest
	static void testGetAsyncJobRequestsByRecordTypeIdWithExistingType() {
		List<AsyncJobRequest__c> mockRecords = createMockJobRequests();
		AsyncJobRequestDistributor distributor = new AsyncJobRequestDistributor(mockRecords);
		
		Test.startTest();
		List<AsyncJobRequest__c> batchableRequests = distributor.getAsyncJobRequestsByRecordTypeId(AsyncJobRequestConstants.recordType.BatchableId);
		Test.stopTest();
		
		Assert.areEqual(3, batchableRequests.size(), 'Should return all records with the specified record type ID');
	}
	
	@IsTest
	static void testGetAsyncJobRequestsByRecordTypeIdWithNonExistingType() {
		List<AsyncJobRequest__c> mockRecords = createMockJobRequests();
		AsyncJobRequestDistributor distributor = new AsyncJobRequestDistributor(mockRecords);
		
		Test.startTest();
		List<AsyncJobRequest__c> noRequests = distributor.getAsyncJobRequestsByRecordTypeId(
			new FakeId(RecordType.SObjectType.getDescribe().getSobjectType()).getFakeId()
		);
		Test.stopTest();
		
		Assert.areEqual(0, noRequests.size(), 'Should return an empty list for non-existing record type');
	}
	
	private static List<AsyncJobRequest__c> createMockJobRequests() {
		List<AsyncJobRequest__c> requests = new List<AsyncJobRequest__c>();
		
		for (Integer i = 0; i < 3; i++) {
			requests.add(new AsyncJobRequest__c(
				JobName__c = 'Batch Job ' + i,
				JobStatus__c = AsyncJobRequestConstants.JobStatus.Waiting.name(),
				RecordTypeId = AsyncJobRequestConstants.recordType.BatchableId

			));
		}
		
		for (Integer i = 0; i < 2; i++) {
			requests.add(new AsyncJobRequest__c(
				JobName__c = 'Queueable Job ' + i,
				JobStatus__c = AsyncJobRequestConstants.JobStatus.Waiting.name(),
				RecordTypeId = AsyncJobRequestConstants.recordType.QueueableId
			));
		}
		
		return requests;
	}
}
