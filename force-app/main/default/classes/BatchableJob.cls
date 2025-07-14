public with sharing abstract class BatchableJob
	extends AsyncJob
	implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts
{

	abstract protected Database.QueryLocator doStart(Database.BatchableContext batchContext);
	abstract protected void doExecute(Database.BatchableContext batchContext, List<SObject> scope);
	abstract protected void doFinish(Database.BatchableContext batchContext);

	public Database.QueryLocator start(Database.BatchableContext batchContext) {
		try {
			EventBus.publish(this.createJobChangeStatusEvent(AsyncJobRequestConstants.JobStatus.Processing, batchContext.getJobId()));
			return (Database.QueryLocator)this.doStart(batchContext);
		} catch (Exception exc) {
			EventBus.publish(this.createJobErrorEvent(exc, batchContext.getJobId()));
			EventBus.publish(this.createJobChangeStatusEvent(AsyncJobRequestConstants.JobStatus.Failed, batchContext.getJobId()));
			throw exc;
		}
	}

	public void execute(Database.BatchableContext batchContext, List<SObject> scope) {
		try {
			this.doExecute(batchContext, scope);
		} catch (Exception exc) {
			EventBus.publish(this.createJobErrorEvent(exc, batchContext.getJobId()));
			throw exc;
		}
	}

	public void finish(Database.BatchableContext batchContext) {
		try {
			this.doFinish(batchContext);
			EventBus.publish(this.createJobChangeStatusEvent(AsyncJobRequestConstants.JobStatus.Completed, batchContext.getJobId()));
		} catch (Exception exc) {
			EventBus.publish(this.createJobErrorEvent(exc, batchContext.getJobId()));
			EventBus.publish(this.createJobChangeStatusEvent(AsyncJobRequestConstants.JobStatus.Failed, batchContext.getJobId()));
			throw exc;
		}
	}

	public class BatchJobException extends Exception {}
}