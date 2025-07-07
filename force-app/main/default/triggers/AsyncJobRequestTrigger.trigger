trigger AsyncJobRequestTrigger on AsyncJobRequest__c (after insert) {
	List<AsyncJob__e> jobEvents = new List<AsyncJob__e>();
	for (AsyncJobRequest__c jobRequestRecord : new AsyncJobRequestDistributor(Trigger.new).getNewAsyncJobRequests()) {
		jobEvents.add(new AsyncJob__e(
			Action__c = AsyncJobEventConstants.Action.QUEUE_JOB.name(),
			JobRequestTypeId__c = jobRequestRecord.RecordTypeId
		));
	}
	if (!jobEvents.isEmpty()) {
		EventBus.publish(jobEvents);
	}
}