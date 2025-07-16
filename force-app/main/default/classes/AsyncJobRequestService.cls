/**
 * @description Service class for handling AsyncJobRequest operations.
 *              Implements a singleton pattern and provides methods to publish job events.
 */
public class AsyncJobRequestService {

	private Boolean bypass = false;
	
	@TestVisible
	public static AsyncJobRequestService instance {
		get{
			if (instance == null) {
				instance = new AsyncJobRequestService();
			}
			return instance;
		}
		private set;
	}

	/**
	 * @description Publishes queue job events for the provided AsyncJobRequest records.
	 * @param asyncJobRequests List of AsyncJobRequest__c records to process.
	 * @return List of Database.SaveResult objects with publishing results
	 */
	public List<Database.SaveResult> publishQueueJobEvents(List<AsyncJobRequest__c> asyncJobRequests) {
		if (bypass) {
			return new List<Database.SaveResult>();
		}
		List<AsyncJob__e> jobEvents = new List<AsyncJob__e>();
		for (AsyncJobRequest__c jobRequestRecord : new AsyncJobRequestDistributor(asyncJobRequests).getNewAsyncJobRequests()) {
			jobEvents.add(new AsyncJob__e(
				Action__c = AsyncJobEventConstants.Action.QUEUE_JOB.name(),
				JobRequestTypeId__c = jobRequestRecord.RecordTypeId
			));
		}
		if (!jobEvents.isEmpty()) {
			return EventBus.publish(jobEvents);
		}
		return new List<Database.SaveResult>();
	}

	/**
	 * @description Enables bypass mode to skip publishing job events.
	 * @return The current instance of AsyncJobRequestService.
	 */
	@TestVisible
	private AsyncJobRequestService setBypass() {
		this.bypass = true;
		return this;
	}

	/**
	 * @description Disables bypass mode to allow publishing job events.
	 * @return The current instance of AsyncJobRequestService.
	 */
	@TestVisible
	private AsyncJobRequestService unsetBypass() {
		this.bypass = false;
		return this;
	}
}
