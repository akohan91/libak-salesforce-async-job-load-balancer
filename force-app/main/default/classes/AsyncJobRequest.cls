public with sharing class AsyncJobRequest {
	private AsyncJobRequest__c asyncJobRequest;

	public AsyncJobRequest(AsyncJobRequest__c asyncJobRequest) {
		this.asyncJobRequest = asyncJobRequest;
	}

	public AsyncJobRequest__c record() {
		return this.asyncJobRequest;
	}

	public AsyncJobRequest setJobId(Id jobId) {
		asyncJobRequest.JobId__c = jobId;
		return this;
	}

	public AsyncJobRequest setJobStatus(AsyncJobRequestConstants.JobStatus status) {
		asyncJobRequest.JobStatus__c = status.name();
		switch on status {
			when Pending {
				asyncJobRequest.RequestedTime__c = Datetime.now();
			}
			when Processing {
				asyncJobRequest.ProcessedTime__c = Datetime.now();
			}
			when Completed {
				asyncJobRequest.FinishedTime__c = Datetime.now();
			}
		}
		return this;
	}

	public AsyncJobRequest addErrorMessage(Exception exc) {
		String errorMessage = String.format(
			AsyncJobRequestConstants.ERROR_TMPL,
			new List<String>{exc.getMessage(), exc.getStackTraceString()}
		);
		this.addErrorMessage(errorMessage);
		return this;
	}

	public AsyncJobRequest addErrorMessage(String errorMessage) {
		if (this.asyncJobRequest.ErrorMessage__c == null) {
			this.asyncJobRequest.ErrorMessage__c = errorMessage;
		} else {
			this.asyncJobRequest.ErrorMessage__c += errorMessage;
		}
		return this;
	}

	public AsyncJobRequest updateRecord() {
		update this.asyncJobRequest;
		return this;
	}
}