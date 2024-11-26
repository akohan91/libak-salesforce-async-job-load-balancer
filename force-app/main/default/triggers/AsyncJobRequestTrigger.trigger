trigger AsyncJobRequestTrigger on AsyncJobRequest__c (after insert) {
	List<AsyncJob__e> asyncJobEvents = new List<AsyncJob__e>();
	for (AsyncJobRequest__c asyncJobRequest : new AsyncJobRequestDistributor(Trigger.new).getNewAsyncJobRequests()) {
		asyncJobEvents.add(new AsyncJob__e(
			Action__c = AsyncJobEventConstants.Action.QUEUE_JOB.name(),
			JobRequestTypeId__c = asyncJobRequest.RecordTypeId
		));
	}
	if (!asyncJobEvents.isEmpty()) {
		EventBus.publish(asyncJobEvents);
	}
}