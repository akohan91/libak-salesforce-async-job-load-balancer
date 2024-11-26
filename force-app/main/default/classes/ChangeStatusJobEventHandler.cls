public with sharing class ChangeStatusJobEventHandler implements IAsyncJobEventHandler {
	private List<AsyncJobRequestConstants.JobStatus> completedStatuses = new List<AsyncJobRequestConstants.JobStatus>{
		AsyncJobRequestConstants.JobStatus.Completed,
		AsyncJobRequestConstants.JobStatus.Failed
	};

	public void handleEvent(AsyncJob__e event) {
		AsyncJobRequest asyncJobRequest = new AsyncJobRequest(
			AsyncJobRequestSelector.instance.getByJobId(event.AsyncJobId__c)
		);
		AsyncJobRequestConstants.JobStatus jobStatus = AsyncJobRequestConstants.JobStatus.valueOf(event.Payload__c);
		asyncJobRequest
			.setJobStatus(jobStatus)
			.updateRecord();
		if (completedStatuses.contains(jobStatus)) {
			EventBus.publish(new AsyncJob__e(
				Action__c = AsyncJobEventConstants.Action.QUEUE_JOB.name(),
				JobRequestTypeId__c = AsyncJobRequestConstants.recordType.BatchableId
			));
		}
	}
}