public with sharing class BatchableJobExecutor implements IAsyncJobExecutor {
	public void executeJob() {
		AsyncJobRequest asyncJobRequest;
		try {
			if (FlexQueueService.instance.getAvailableFlexQueueSpace() == 0) {
				return;
			}
			asyncJobRequest = new AsyncJobRequest(
				AsyncJobRequestSelector.instance.getFirstBatchQueueItem()
			);
			Type classType = Type.forName(asyncJobRequest.record().JobName__c);
			BatchJob batchJobInstance = (BatchJob)classType.newInstance();
			asyncJobRequest
				.setJobId(Database.executeBatch(
					batchJobInstance,
					Integer.valueOf(asyncJobRequest.record().BatchSize__c))
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