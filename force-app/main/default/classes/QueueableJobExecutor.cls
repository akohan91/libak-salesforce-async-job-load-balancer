public with sharing class QueueableJobExecutor implements IAsyncJobExecutor {
	public void executeJob() {
		AsyncJobRequest asyncJobRequest;
		try {
			asyncJobRequest = new AsyncJobRequest(
				AsyncJobRequestSelector.instance.getFirstQueueableQueueItem()
			);
			Type classType = Type.forName(asyncJobRequest.record().JobName__c);
			QueueableJob queueableJobInstance = (QueueableJob)classType.newInstance();
			asyncJobRequest.setJobId(
				System.enqueueJob(queueableJobInstance)
			).setJobStatus(AsyncJobRequestConstants.JobStatus.Pending);
		} catch (Exception exc) {
			asyncJobRequest
				.setJobStatus(AsyncJobRequestConstants.JobStatus.Failed)
				.addErrorMessage(exc);
		} finally {
			asyncJobRequest.updateRecord();
		}
	}
}