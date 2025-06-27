public with sharing virtual class AsyncJob {
	
	public AsyncJob__e createJobErrorEvent(Exception exc, Id asyncJobId) {
		String errorMessage = String.format(
			AsyncJobRequestConstants.ERROR_TMPL,
			new List<String>{exc.getMessage(), exc.getStackTraceString()}
		);
		return new AsyncJob__e(
			Action__c = AsyncJobEventConstants.Action.ADD_ERROR.name(),
			AsyncJobId__c = asyncJobId,
			Payload__c = errorMessage
		);
	}

	public AsyncJob__e createJobChangeStatusEvent(AsyncJobRequestConstants.JobStatus status, Id asyncJobId) {
		return new AsyncJob__e(
			Action__c = AsyncJobEventConstants.Action.CHANGE_STATUS.name(),
			AsyncJobId__c = asyncJobId,
			Payload__c = status.name()
		);
	}
}