public with sharing class BatchableFlexQueueService {
	public static BatchableFlexQueueService instance {
		get{
			if (instance == null) {
				instance = new BatchableFlexQueueService();
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
		Integer availableSlots = 100 - holdingJobsCount;
		return availableSlots;
	}
}