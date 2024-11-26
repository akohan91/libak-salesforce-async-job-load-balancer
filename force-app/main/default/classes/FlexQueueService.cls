public with sharing class FlexQueueService {
	public static FlexQueueService instance {
		get{
			if (instance == null) {
				instance = new FlexQueueService();
			}
			return instance;
		}
		set;
	}

	public Integer getAvailableFlexQueueSpace() {
		Integer holdingJobsCount = [
			SELECT COUNT()
			FROM AsyncApexJob
			WHERE JobType = 'BatchApex'
				AND Status = 'Holding'
		];
		Integer availableSpace = 3 - holdingJobsCount;
		return availableSpace;
	}
}