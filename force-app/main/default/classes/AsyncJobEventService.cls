public with sharing class AsyncJobEventService {
	public static AsyncJobEventService instance {
		get{
			if (instance == null) {
				instance = new AsyncJobEventService();
			}
			return instance;
		}
		set;
	}

	private Map<AsyncJobEventConstants.Action, IAsyncJobEventHandler> asyncJobEventHandlers = new Map<AsyncJobEventConstants.Action, IAsyncJobEventHandler>{
		AsyncJobEventConstants.Action.ADD_ERROR => new ErrorJobEventHandler(),
		AsyncJobEventConstants.Action.CHANGE_STATUS => new ChangeStatusJobEventHandler(),
		AsyncJobEventConstants.Action.QUEUE_JOB => new QueueJobEventHandler()
	};

	public void handleEvent(AsyncJob__e event) {
		IAsyncJobEventHandler handler = this.asyncJobEventHandlers.get(AsyncJobEventConstants.Action.valueOf(event.Action__c));
		handler.handleEvent(event);
	}
}