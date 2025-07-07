public with sharing class AsyncJobRequestDistributor {
	private final List<AsyncJobRequest__c> newJobRequestRecords;
	private final Map<Id, AsyncJobRequest__c> idToOldJobRequestRecord;
	private final Map<Id, List<AsyncJobRequest__c>> recordTypeIdToJobRequestRecords;

	public AsyncJobRequestDistributor(List<AsyncJobRequest__c> newJobRequestRecords) {
		this(newJobRequestRecords, new Map<Id, AsyncJobRequest__c>());
	}

	public AsyncJobRequestDistributor(List<AsyncJobRequest__c> newJobRequestRecords, Map<Id, AsyncJobRequest__c> idToOldJobRequestRecord) {
		this.newJobRequestRecords = newJobRequestRecords;
		this.idToOldJobRequestRecord = idToOldJobRequestRecord;
		this.recordTypeIdToJobRequestRecords = new Map<Id, List<AsyncJobRequest__c>>();
		this.dispatchRecords();
	}

	public List<AsyncJobRequest__c> getNewAsyncJobRequests() {
		return this.newJobRequestRecords;
	}

	public List<AsyncJobRequest__c> getBatchableAsyncJobRequests() {
		return this.getAsyncJobRequestsByRecordTypeId(AsyncJobRequestConstants.recordType.BatchableId);
	}

	public List<AsyncJobRequest__c> getQueueableAsyncJobRequests() {
		return this.getAsyncJobRequestsByRecordTypeId(AsyncJobRequestConstants.recordType.QueueableId);
	}

	public List<AsyncJobRequest__c> getAsyncJobRequestsByRecordTypeId(Id recordTypeId) {
		return this.recordTypeIdToJobRequestRecords.containsKey(recordTypeId)
			? this.recordTypeIdToJobRequestRecords.get(recordTypeId)
			: new List<AsyncJobRequest__c>();
	}

	private void dispatchRecords() {
		for (AsyncJobRequest__c jobRequest : this.newJobRequestRecords) {
			if (!this.recordTypeIdToJobRequestRecords.containsKey(jobRequest.RecordTypeId)) {
				this.recordTypeIdToJobRequestRecords.put(jobRequest.RecordTypeId, new List<AsyncJobRequest__c>());
			}
			this.recordTypeIdToJobRequestRecords.get(jobRequest.RecordTypeId).add(jobRequest);
		}
	}
}