public with sharing class BatchJob implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {
	private Database.Batchable<SObject> batchJobInstance;

	public BatchJob(Object batchJobInstance) {
		if (!(batchJobInstance instanceof Database.Batchable<SObject>)) {
			throw new BatchJobException('The class must implement the Database.Batchable<SObject> interface.');
		}
		this.batchJobInstance = (Database.Batchable<SObject>) batchJobInstance;
	}

	public Database.QueryLocator start(Database.BatchableContext batchContext) {
		try {
			EventBus.publish(
				this.createJobChangeStatusEvent(AsyncJobRequestConstants.JobStatus.Processing, batchContext.getJobId())
			);
			return (Database.QueryLocator)this.batchJobInstance.start(batchContext);
		} catch (Exception exc) {
			EventBus.publish(
				new List<AsyncJob__e>{
					this.createJobErrorEvent(exc, batchContext.getJobId()),
					this.createJobChangeStatusEvent(AsyncJobRequestConstants.JobStatus.Failed, batchContext.getJobId())
				}
			);
			throw exc;
		}
	}

	public void execute(Database.BatchableContext batchContext, List<SObject> scope) {
		try {
			this.batchJobInstance.execute(batchContext, scope);
		} catch (Exception exc) {
			EventBus.publish(
				this.createJobErrorEvent(exc, batchContext.getJobId())
			);
			throw exc;
		}
	}

	public void finish(Database.BatchableContext batchContext) {
		try {
			this.batchJobInstance.finish(batchContext);
		} catch (Exception exc) {
			EventBus.publish(
				this.createJobErrorEvent(exc, batchContext.getJobId())
			);
		} finally {
			EventBus.publish(
				this.createJobChangeStatusEvent(AsyncJobRequestConstants.JobStatus.Completed, batchContext.getJobId())
			);
		}
		
	}

	private AsyncJob__e createJobErrorEvent(Exception exc, Id asyncJobId) {
		String errorMessage = String.format(
			AsyncJobRequestConstants.ERROR_TMPL,
			new List<String>{exc.getMessage(), exc.getStackTraceString()}
		);
		return new AsyncJob__e(
			Action__c = AsyncJobEventConstants.Action.ADD_ERROR.name(),
			AsyncJobId__c = asyncJobId,
			Payload__c = errorMessage
		);
	}

	private AsyncJob__e createJobChangeStatusEvent(AsyncJobRequestConstants.JobStatus status, Id asyncJobId) {
		return new AsyncJob__e(
			Action__c = AsyncJobEventConstants.Action.CHANGE_STATUS.name(),
			AsyncJobId__c = asyncJobId,
			Payload__c = status.name()
		);
	}

	public class BatchJobException extends Exception {}
}