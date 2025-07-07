public with sharing class AsyncJobRequest {
	private AsyncJobRequest__c jobRequestRecord;

	public AsyncJobRequest(AsyncJobRequest__c jobRequestRecord) {
		this.jobRequestRecord = jobRequestRecord;
	}

	public AsyncJobRequest__c record() {
		return this.jobRequestRecord;
	}

	public AsyncJobRequest setJobId(Id jobId) {
		jobRequestRecord.JobId__c = jobId;
		return this;
	}

	public AsyncJobRequest setJobStatus(AsyncJob.ChangeStatusPayload statusPayload) {
		jobRequestRecord.JobStatus__c = statusPayload.status.name();
		switch on statusPayload.status {
			when Pending {
				jobRequestRecord.RequestedTime__c = statusPayload.changedDatetime;
			}
			when Processing {
				jobRequestRecord.ProcessedTime__c = statusPayload.changedDatetime;
			}
			when Completed {
				jobRequestRecord.FinishedTime__c = statusPayload.changedDatetime;
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
		if (this.jobRequestRecord.ErrorMessage__c == null) {
			this.jobRequestRecord.ErrorMessage__c = errorMessage;
		} else {
			this.jobRequestRecord.ErrorMessage__c += errorMessage;
		}
		return this;
	}

	public AsyncJobRequest updateRecord() {
		update this.jobRequestRecord;
		return this;
	}
}