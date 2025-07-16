public with sharing class QueueJobEventHandler implements IAsyncJobEventHandler {
	private Map<Id, IAsyncJobExecutor> recordTypeToProcessorMap = new Map<Id, IAsyncJobExecutor>{
		AsyncJobRequestConstants.recordType.BatchableId => new BatchableJobProcessor(),
		AsyncJobRequestConstants.recordType.QueueableId => new QueueableJobProcessor()
	};

	public void handleEvent(AsyncJob__e event) {
		IAsyncJobExecutor jobExecutor = this.recordTypeToProcessorMap.get(event.JobRequestTypeId__c);
		jobExecutor.executeJob();
	}
}
