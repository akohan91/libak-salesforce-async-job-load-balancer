/**
 * Mock implementation of BatchableJob for testing
 */
@IsTest
public class BatchJobProcessorTestBatchableJob extends BatchableJob {
	public Boolean startCalled = false;
	public Boolean executeCalled = false;
	public Boolean finishCalled = false;
	
	protected override Database.QueryLocator doStart(Database.BatchableContext bc) {
		startCalled = true;
		return Database.getQueryLocator('SELECT Id FROM User LIMIT 1');
	}
	
	protected override void doExecute(Database.BatchableContext bc, List<SObject> scope) {
		executeCalled = true;
	}
	
	protected override void doFinish(Database.BatchableContext bc) {
		finishCalled = true;
	}
}