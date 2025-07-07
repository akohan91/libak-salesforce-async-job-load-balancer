public with sharing class ErrorJobEventHandler implements IAsyncJobEventHandler {
	public void handleEvent(AsyncJob__e event) {
		AsyncJobRequest jobRequest = new AsyncJobRequest(
			AsyncJobRequestSelector.instance.getByJobId(event.AsyncJobId__c)
		);
		jobRequest
			.addErrorMessage(event.Payload__c)
			.updateRecord();
	}
}