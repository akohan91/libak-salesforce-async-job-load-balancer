public with sharing abstract class QueueableJob
	extends AsyncJob
	implements Queueable, Finalizer, Database.AllowsCallouts {

	abstract protected void doExecute(QueueableContext context);

	public void execute(QueueableContext context) {
		try {
			EventBus.publish(
				this.createJobChangeStatusEvent(AsyncJobRequestConstants.JobStatus.Processing, context.getJobId())
			);
			this.doExecute(context);
		} catch (Exception exc) {
			throw exc;
		} finally {
			System.attachFinalizer(this);
		}
	}

	public void execute(System.FinalizerContext context) {
		if (context.getResult() == System.ParentJobResult.UNHANDLED_EXCEPTION) {
			EventBus.publish(
				new List<AsyncJob__e>{
					this.createJobErrorEvent(context.getException(), context.getAsyncApexJobId()),
					this.createJobChangeStatusEvent(AsyncJobRequestConstants.JobStatus.Failed, context.getAsyncApexJobId())
				}
			);
		}
		EventBus.publish(
			new List<AsyncJob__e>{
				this.createJobChangeStatusEvent(AsyncJobRequestConstants.JobStatus.Completed, context.getAsyncApexJobId())
			}
		);
	}
}
