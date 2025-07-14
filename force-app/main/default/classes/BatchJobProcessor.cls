public with sharing class BatchJobProcessor implements IAsyncJobExecutor {
	public void executeJob() {
		AsyncJobRequest jobRequest;
		try {
			if (BatchFlexQueueService.instance.getAvailableFlexQueueSlots() == 0) {
				return;
			}
			AsyncJobRequest__c jobRequestRecord = AsyncJobRequestSelector.instance.getFirstBatchQueueItem();
			if (jobRequestRecord == null) {
				return;
			}
			jobRequest = new AsyncJobRequest(jobRequestRecord);
			Type jobClassType = Type.forName(jobRequest.record().JobName__c);
			BatchableJob batchJobInstance = (BatchableJob)jobClassType.newInstance();
			batchJobInstance.withPayload(jobRequest.record().Payload__c);
			jobRequest.setJobId(Database.executeBatch(
				batchJobInstance,
				Integer.valueOf(jobRequest.record().BatchSize__c))
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