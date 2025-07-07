public with sharing class QueueableJobProcessor implements IAsyncJobExecutor {
	public void executeJob() {
		AsyncJobRequest jobRequest;
		try {
			jobRequest = new AsyncJobRequest(
				AsyncJobRequestSelector.instance.getFirstQueueableQueueItem()
			);
			Type jobClassType = Type.forName(jobRequest.record().JobName__c);
			QueueableJob queueableJobInstance = (QueueableJob)jobClassType.newInstance();
			queueableJobInstance.withPayload(jobRequest.record().Payload__c);
			jobRequest.setJobId(
				System.enqueueJob(queueableJobInstance)
			).setJobStatus(new AsyncJob.ChangeStatusPayload(AsyncJobRequestConstants.JobStatus.Pending, Datetime.now()));
		} catch (Exception exc) {
			jobRequest
				.setJobStatus(new AsyncJob.ChangeStatusPayload(AsyncJobRequestConstants.JobStatus.Failed, Datetime.now()))
				.addErrorMessage(exc);
		} finally {
			jobRequest.updateRecord();
		}
	}
}