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