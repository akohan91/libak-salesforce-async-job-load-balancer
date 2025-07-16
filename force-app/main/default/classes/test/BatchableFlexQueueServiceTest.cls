@IsTest
private class BatchableFlexQueueServiceTest {
	
	@IsTest
	static void testSingletonPattern() {
		// Test singleton pattern behavior
		Test.startTest();
		BatchableFlexQueueService instance1 = BatchableFlexQueueService.instance;
		BatchableFlexQueueService instance2 = BatchableFlexQueueService.instance;
		Test.stopTest();
		
		// Verify both instances are the same object
		System.assert(instance1 === instance2, 'Should return the same instance');
		Assert.isNotNull(instance1, 'Instance should not be null');
	}
	
	@IsTest
	static void testGetAvailableFlexQueueSlotsWithNoHoldingJobs() {
		
		Test.startTest();
		Integer availableSlots = BatchableFlexQueueService.instance.getAvailableFlexQueueSlots();
		Test.stopTest();
		
		// When no jobs are holding, all 100 slots should be available
		Assert.areEqual(100, availableSlots, 'With no holding jobs, all slots should be available');
	}
}
