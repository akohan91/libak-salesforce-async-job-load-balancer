public with sharing class QueueableJobProcessor implements IAsyncJobExecutor {
	public void executeJob() {
		AsyncJobRequest jobRequest;
		try {
			AsyncJobRequest__c jobRequestRecord = AsyncJobRequestSelector.instance.getFirstQueueableQueueItem();
			if (jobRequestRecord == null) {
				return;
			}
			jobRequest = new AsyncJobRequest(jobRequestRecord);
			Type jobClassType = Type.forName(jobRequest.record().JobName__c);
			QueueableJob queueableJobInstance = (QueueableJob)jobClassType.newInstance();
			queueableJobInstance.withPayload(jobRequest.record().Payload__c);
			jobRequest.setJobId(
				System.enqueueJob(queueableJobInstance)
			).setJobStatus(new AsyncJob.ChangeStatusPayload(AsyncJobRequestConstants.JobStatus.Pending, Datetime.now()))
			.updateRecord();
		} catch (Exception exc) {
			jobRequest
				.setJobStatus(new AsyncJob.ChangeStatusPayload(AsyncJobRequestConstants.JobStatus.Failed, Datetime.now()))
				.addErrorMessage(exc)
				.updateRecord();
		}
	}
}