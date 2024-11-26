public with sharing class AsyncJobRequestConstants {
	
	public static final String ERROR_TMPL = '\rError Message:\r{0}\rStack Trace:\r{1}';

	public enum JobStatus {
		Waiting,
		Pending,
		Processing,
		Completed,
		Failed
	}

	public enum RecordTypeName {
		Batchable,
		Queueable
	}

	public static RecordType recordType {
		get {
			if (recordType == null) {
				recordType = new RecordType();
		}
			return recordType;
		} set;
	}
	
	public class RecordType {
		private Map<String, Schema.RecordTypeInfo> recordTypeNameToInfo;

		public Id BatchableId { get; private set; }
		public Id QueueableId { get; private set; }

		public RecordType() {
			this.recordTypeNameToInfo = Schema.getGlobalDescribe()
				.get(String.valueOf(AsyncJobRequest__c.SObjectType))
				.getDescribe()
				.getRecordTypeInfosByDeveloperName();
			
			this.BatchableId = getIdByName(RecordTypeName.Batchable.name());
			this.QueueableId = getIdByName(RecordTypeName.Queueable.name());
		}

		private Id getIdByName(String recordTypeName) {
			Schema.RecordTypeInfo recordTypeInfo = this.recordTypeNameToInfo.get(recordTypeName);
			return recordTypeInfo != null ? recordTypeInfo.getRecordTypeId() : null;
		}
	}
}
