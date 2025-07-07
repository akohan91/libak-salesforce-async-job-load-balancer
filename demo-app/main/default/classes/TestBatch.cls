public with sharing class TestBatch extends BatchableJob {
	protected override Database.QueryLocator doStart(Database.BatchableContext batchContext) {
		return Database.getQueryLocator('SELECT Id FROM Account');
	}

	protected override void doExecute(Database.BatchableContext batchContext, List<SObject> scope) {
		Datetime waitTo = Datetime.now().addSeconds(8);
		while (Datetime.now() < waitTo) {}
	}

	protected override void doFinish(Database.BatchableContext batchContext) {
		
	}
}