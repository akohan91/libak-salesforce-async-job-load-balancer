public with sharing class BatchFlexQueueService {
	public static BatchFlexQueueService instance {
		get{
			if (instance == null) {
				instance = new BatchFlexQueueService();
			}
			return instance;
		}
		set;
	}

	public Integer getAvailableFlexQueueSlots() {
		Integer holdingJobsCount = [
			SELECT COUNT()
			FROM AsyncApexJob
			WHERE JobType = 'BatchApex'
				AND Status = 'Holding'
		];
		Integer availableSlots = 3 - holdingJobsCount;
		return availableSlots;
	}
}