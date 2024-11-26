public with sharing class ErrorJobEventHandler implements IAsyncJobEventHandler {
	public void handleEvent(AsyncJob__e event) {
		AsyncJobRequest asyncJobRequest = new AsyncJobRequest(
			AsyncJobRequestSelector.instance.getByJobId(event.AsyncJobId__c)
		);
		asyncJobRequest
			.addErrorMessage(event.Payload__c)
			.updateRecord();

	}
}