public with sharing class AsyncJobRequestSelector {

	public static AsyncJobRequestSelector instance {
		get {
			if (instance == null) {
				instance = new AsyncJobRequestSelector();
			}
			return instance;
		}
		set;
	}

	public AsyncJobRequest__c getById(Id asyncJobRequestId) {
		return [
			SELECT Id,
				BatchSize__c,
				ErrorMessage__c,
				FinishedTime__c,
				JobId__c,
				JobName__c,
				JobStatus__c,
				Payload__c,
				ProcessedTime__c,
				RecordType.DeveloperName,
				RequestedTime__c
			FROM AsyncJobRequest__c
			WHERE Id = :asyncJobRequestId
		];
	}

	public AsyncJobRequest__c getByJobId(Id jobId) {
		return [
			SELECT Id,
				BatchSize__c,
				ErrorMessage__c,
				FinishedTime__c,
				JobId__c,
				JobName__c,
				JobStatus__c,
				Payload__c,
				ProcessedTime__c,
				RecordType.DeveloperName,
				RequestedTime__c
			FROM AsyncJobRequest__c
			WHERE JobId__c = :jobId
		];
	}

	public AsyncJobRequest__c getFirstBatchQueueItem() {
		List<AsyncJobRequest__c> jobRequests = [
			SELECT Id,
				BatchSize__c,
				ErrorMessage__c,
				FinishedTime__c,
				JobStatus__c,
				JobId__c,
				JobName__c,
				Payload__c,
				ProcessedTime__c,
				RequestedTime__c
			FROM AsyncJobRequest__c
			WHERE JobStatus__c = :AsyncJobRequestConstants.JobStatus.Waiting.name()
				AND RecordTypeId = :AsyncJobRequestConstants.recordType.BatchableId
			ORDER BY CreatedDate
			LIMIt 1
		];
		
		return jobRequests.size() > 0 ? jobRequests.get(0) : null;
	}

	public AsyncJobRequest__c getFirstQueueableQueueItem() {
		List<AsyncJobRequest__c> jobRequests = [
			SELECT Id,
				BatchSize__c,
				ErrorMessage__c,
				FinishedTime__c,
				JobStatus__c,
				JobId__c,
				JobName__c,
				Payload__c,
				ProcessedTime__c,
				RequestedTime__c
			FROM AsyncJobRequest__c
			WHERE JobStatus__c = :AsyncJobRequestConstants.JobStatus.Waiting.name()
				AND RecordTypeId = :AsyncJobRequestConstants.recordType.QueueableId
			ORDER BY CreatedDate
			LIMIt 1
		];
		
		return jobRequests.size() > 0 ? jobRequests.get(0) : null;
	}
	
	public List<AsyncJobRequest__c> getByJobStatus(String jobStatus) {
		return [
			SELECT Id,
				BatchSize__c,
				ErrorMessage__c,
				FinishedTime__c,
				JobStatus__c,
				JobId__c,
				JobName__c,
				Payload__c,
				ProcessedTime__c,
				RequestedTime__c
			FROM AsyncJobRequest__c
			WHERE JobStatus__c = :jobStatus
			ORDER BY CreatedDate
		];
	}
}