public with sharing virtual class AsyncJob {

	protected String jobPayload;

	public AsyncJob withPayload(String payload) {
		this.jobPayload = payload;
		return this;
	}
	
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

	public AsyncJob__e createJobChangeStatusEvent(AsyncJobRequestConstants.JobStatus newStatus, Id asyncJobId) {
		return new AsyncJob__e(
			Action__c = AsyncJobEventConstants.Action.CHANGE_STATUS.name(),
			AsyncJobId__c = asyncJobId,
			Payload__c = new ChangeStatusPayload(newStatus, Datetime.now()).json()
		);
	}

	public class ChangeStatusPayload {
		public AsyncJobRequestConstants.JobStatus status {get; private set;}
		public Datetime changedDatetime {get; private set;}

		public ChangeStatusPayload(AsyncJobRequestConstants.JobStatus status, Datetime changedDatetime) {
			this.status = status;
			this.changedDatetime = changedDatetime;
		}

		public String json() {
			return JSON.serialize(this);
		}
	}
}