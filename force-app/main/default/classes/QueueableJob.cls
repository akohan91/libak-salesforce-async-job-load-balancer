public with sharing abstract class QueueableJob
	extends AsyncJob
	implements Queueable, Finalizer, Database.AllowsCallouts
{

	abstract protected void doExecute(QueueableContext context);

	public void execute(QueueableContext context) {
		System.attachFinalizer((Finalizer)this);
		EventBus.publish(this.createJobChangeStatusEvent(AsyncJobRequestConstants.JobStatus.Processing, context.getJobId()));
		this.doExecute(context);
	}

	public void execute(System.FinalizerContext context) {
		if (context.getResult() == System.ParentJobResult.UNHANDLED_EXCEPTION) {
			EventBus.publish(this.createJobErrorEvent(context.getException(), context.getAsyncApexJobId()));
			EventBus.publish(this.createJobChangeStatusEvent(AsyncJobRequestConstants.JobStatus.Failed, context.getAsyncApexJobId()));
		} else {
			EventBus.publish(this.createJobChangeStatusEvent(AsyncJobRequestConstants.JobStatus.Completed, context.getAsyncApexJobId()));
		}
	}
}
