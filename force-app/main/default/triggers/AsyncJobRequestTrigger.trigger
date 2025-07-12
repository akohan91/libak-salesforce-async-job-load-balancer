trigger AsyncJobRequestTrigger on AsyncJobRequest__c (after insert) {
	AsyncJobRequestService.instance.publishQueueJobEvents(Trigger.new);
}