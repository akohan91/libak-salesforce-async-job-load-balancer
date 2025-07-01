public with sharing class QueueableJobExecutor implements IAsyncJobExecutor {
	public void executeJob() {
		AsyncJobRequest asyncJobRequest;
		try {
			asyncJobRequest = new AsyncJobRequest(
				AsyncJobRequestSelector.instance.getFirstQueueableQueueItem()
			);
			Type classType = Type.forName(asyncJobRequest.record().JobName__c);
			QueueableJob queueableJobInstance = (QueueableJob)classType.newInstance();
			queueableJobInstance.withPayload(asyncJobRequest.record().Payload__c);
			asyncJobRequest.setJobId(
				System.enqueueJob(queueableJobInstance)
			).setJobStatus(new AsyncJob.ChangeStatusPayload(AsyncJobRequestConstants.JobStatus.Pending, Datetime.now()));
		} catch (Exception exc) {
			asyncJobRequest
				.setJobStatus(new AsyncJob.ChangeStatusPayload(AsyncJobRequestConstants.JobStatus.Failed, Datetime.now()))
				.addErrorMessage(exc);
		} finally {
			asyncJobRequest.updateRecord();
		}
	}
}