@IsTest
private class AsyncJobEventServiceTest {
	
	private class MockAsyncJobEventHandler implements IAsyncJobEventHandler {
		public Boolean handlerCalled = false;
		public AsyncJob__e lastEvent;
		
		public void handleEvent(AsyncJob__e event) {
			this.handlerCalled = true;
			this.lastEvent = event;
		}
	}
	
	@IsTest
	static void testSingletonPattern() {
		Test.startTest();
		AsyncJobEventService instance1 = AsyncJobEventService.instance;
		AsyncJobEventService instance2 = AsyncJobEventService.instance;
		Test.stopTest();
		
		System.assert(instance1 === instance2, 'Should return the same instance');
	}
	
	@IsTest
	static void testHandleAddErrorEvent() {
		MockAsyncJobEventHandler mockHandler = new MockAsyncJobEventHandler();
		AsyncJobEventService service = new AsyncJobEventService();
		
		service.setEventHandler(AsyncJobEventConstants.Action.ADD_ERROR, mockHandler);
		
		AsyncJob__e errorEvent = new AsyncJob__e(
			Action__c = AsyncJobEventConstants.Action.ADD_ERROR.name(),
			AsyncJobId__c = new FakeId(AsyncJob__e.SObjectType).getFakeId(),
			Payload__c = 'Test error payload'
		);
		
		Test.startTest();
		service.handleEvent(errorEvent);
		Test.stopTest();
		
		Assert.isTrue(mockHandler.handlerCalled, 'ADD_ERROR handler should be called');
		Assert.areEqual(errorEvent, mockHandler.lastEvent, 'Event passed to handler should match the original event');
	}
	
	@IsTest
	static void testHandleChangeStatusEvent() {
		MockAsyncJobEventHandler mockHandler = new MockAsyncJobEventHandler();
		AsyncJobEventService service = new AsyncJobEventService();
		
		service.setEventHandler(AsyncJobEventConstants.Action.CHANGE_STATUS, mockHandler);
		
		AsyncJob.ChangeStatusPayload payload = new AsyncJob.ChangeStatusPayload(
			AsyncJobRequestConstants.JobStatus.Completed, Datetime.now());
		AsyncJob__e statusEvent = new AsyncJob__e(
			Action__c = AsyncJobEventConstants.Action.CHANGE_STATUS.name(),
			AsyncJobId__c = new FakeId(AsyncJob__e.SObjectType).getFakeId(),
			Payload__c = payload.json()
		);
		
		Test.startTest();
		service.handleEvent(statusEvent);
		Test.stopTest();
		
		Assert.isTrue(mockHandler.handlerCalled, 'CHANGE_STATUS handler should be called');
		Assert.areEqual(statusEvent, mockHandler.lastEvent, 'Event passed to handler should match the original event');
	}
	
	@IsTest
	static void testHandleQueueJobEvent() {
		MockAsyncJobEventHandler mockHandler = new MockAsyncJobEventHandler();
		AsyncJobEventService service = new AsyncJobEventService();
		
		service.setEventHandler(AsyncJobEventConstants.Action.QUEUE_JOB, mockHandler);
		
		AsyncJob__e queueEvent = new AsyncJob__e(
			Action__c = AsyncJobEventConstants.Action.QUEUE_JOB.name(),
			JobRequestTypeId__c = new FakeId(AsyncJob__e.SObjectType).getFakeId()
		);
		
		Test.startTest();
		service.handleEvent(queueEvent);
		Test.stopTest();
		
		Assert.isTrue(mockHandler.handlerCalled, 'QUEUE_JOB handler should be called');
		Assert.areEqual(queueEvent, mockHandler.lastEvent, 'Event passed to handler should match the original event');
	}
}