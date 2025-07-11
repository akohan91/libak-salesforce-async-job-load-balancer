public with sharing class ChangeStatusJobEventHandler implements IAsyncJobEventHandler {
	private List<AsyncJobRequestConstants.JobStatus> finalStatuses = new List<AsyncJobRequestConstants.JobStatus>{
		AsyncJobRequestConstants.JobStatus.Completed,
		AsyncJobRequestConstants.JobStatus.Failed
	};

	public void handleEvent(AsyncJob__e event) {
		AsyncJobRequest jobRequest = new AsyncJobRequest(
			AsyncJobRequestSelector.instance.getByJobId(event.AsyncJobId__c)
		);
		AsyncJob.ChangeStatusPayload statusPayload = (AsyncJob.ChangeStatusPayload)JSON.deserialize(event.Payload__c, AsyncJob.ChangeStatusPayload.class);
		jobRequest
			.setJobStatus(statusPayload)
			.updateRecord();
		if (finalStatuses.contains(statusPayload.status)) {
			EventBus.publish(new AsyncJob__e(
				Action__c = AsyncJobEventConstants.Action.QUEUE_JOB.name(),
				JobRequestTypeId__c = jobRequest.record().RecordTypeId
			));
		}
	}
}