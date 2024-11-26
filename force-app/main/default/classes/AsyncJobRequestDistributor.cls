public with sharing class AsyncJobRequestDistributor {
	private final List<AsyncJobRequest__c> newAsyncJobRequests;
	private final Map<Id, AsyncJobRequest__c> idToOldAsyncJobRequest;
	private final Map<Id, List<AsyncJobRequest__c>> recordTypeIdToAsyncJobRequests;

	public AsyncJobRequestDistributor(List<AsyncJobRequest__c> newAsyncJobRequests) {
		this(newAsyncJobRequests, new Map<Id, AsyncJobRequest__c>());
	}

	public AsyncJobRequestDistributor(List<AsyncJobRequest__c> newAsyncJobRequests, Map<Id, AsyncJobRequest__c> idToOldAsyncJobRequest) {
		this.newAsyncJobRequests = newAsyncJobRequests;
		this.idToOldAsyncJobRequest = idToOldAsyncJobRequest;
		this.recordTypeIdToAsyncJobRequests = new Map<Id, List<AsyncJobRequest__c>>();
		this.dispatchRecords();
	}

	public List<AsyncJobRequest__c> getNewAsyncJobRequests() {
		return this.newAsyncJobRequests;
	}

	public List<AsyncJobRequest__c> getBatchableAsyncJobRequests() {
		return this.getAsyncJobRequestsByRecordTypeId(AsyncJobRequestConstants.recordType.BatchableId);
	}

	public List<AsyncJobRequest__c> getQueueableAsyncJobRequests() {
		return this.getAsyncJobRequestsByRecordTypeId(AsyncJobRequestConstants.recordType.QueueableId);
	}

	public List<AsyncJobRequest__c> getAsyncJobRequestsByRecordTypeId(Id recordTypeId) {
		return this.recordTypeIdToAsyncJobRequests.containsKey(recordTypeId)
			? this.recordTypeIdToAsyncJobRequests.get(recordTypeId)
			: new List<AsyncJobRequest__c>();
	}

	private void dispatchRecords() {
		for (AsyncJobRequest__c asyncJobRequest : this.newAsyncJobRequests) {
			if (!this.recordTypeIdToAsyncJobRequests.containsKey(asyncJobRequest.RecordTypeId)) {
				this.recordTypeIdToAsyncJobRequests.put(asyncJobRequest.RecordTypeId, new List<AsyncJobRequest__c>());
			}
			this.recordTypeIdToAsyncJobRequests.get(asyncJobRequest.RecordTypeId).add(asyncJobRequest);
		}
	}
}