public class AsyncJobRequestScheduler implements Schedulable {
	
	private Integer numberOfJobs;
	private Integer rescheduleMinutes;
	
	public AsyncJobRequestScheduler() {
		this.numberOfJobs = 100;
		this.rescheduleMinutes = 2;
	}
	
	public AsyncJobRequestScheduler(Integer numberOfJobs, Integer rescheduleMinutes) {
		this.numberOfJobs = numberOfJobs;
		this.rescheduleMinutes = rescheduleMinutes;
	}
	
	public void execute(SchedulableContext ctx) {
		createAsyncJobRequests();
		if (ctx != null) {
			System.abortJob(ctx.getTriggerId());
		}
		scheduleJob(rescheduleMinutes);
	}
	
	private void createAsyncJobRequests() {
		List<AsyncJobRequest__c> jobRequests = new List<AsyncJobRequest__c>();
		for (Integer i = 0; i < numberOfJobs; i++) {
			jobRequests.add(
				new AsyncJobRequest__c(
					RecordTypeId = AsyncJobRequestConstants.recordType.QueueableId,
					JobName__c = TestQueueable.class.getName(),
					Payload__c = 'Something in the queueable payload...'
				)
			);
			jobRequests.add(
				new AsyncJobRequest__c(
					RecordTypeId = AsyncJobRequestConstants.recordType.BatchableId,
					JobName__c = TestBatch.class.getName(),
					BatchSize__c = 200,
					Payload__c = 'Something in the batchable payload...'
				)
			);
		}
		insert jobRequests;
	}
	
	public static Id scheduleJob(Integer initialDelayMinutes) {
		return System.schedule(
			AsyncJobRequestScheduler.class.getName()+ '-' + Datetime.now().getTime(),
			Datetime.now().addMinutes(initialDelayMinutes).format('0 m H d M ? y'),
			new AsyncJobRequestScheduler()
		);
	}
}