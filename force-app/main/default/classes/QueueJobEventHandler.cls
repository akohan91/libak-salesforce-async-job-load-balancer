public with sharing class QueueJobEventHandler implements IAsyncJobEventHandler {
	private Map<Id, IAsyncJobExecutor> asyncJobExecutors = new Map<Id, IAsyncJobExecutor>{
		AsyncJobRequestConstants.recordType.BatchableId => new BatchableJobExecutor(),
		AsyncJobRequestConstants.recordType.QueueableId => new QueueableJobExecutor()
	};

	public void handleEvent(AsyncJob__e event) {
		IAsyncJobExecutor executor = this.asyncJobExecutors.get(event.JobRequestTypeId__c);
		executor.executeJob();
	}
}
