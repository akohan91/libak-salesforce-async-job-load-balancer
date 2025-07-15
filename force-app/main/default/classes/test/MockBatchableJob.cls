/**
 * Test implementation of BatchableJob for testing
 */
@IsTest
public class MockBatchableJob extends BatchableJob {
	public Boolean startCalled = false;
	public Boolean executeCalled = false;
	public Boolean finishCalled = false;
	public Exception startException;
	public Exception executeException;
	public Exception finishException;
	
	protected override Database.QueryLocator doStart(Database.BatchableContext bc) {
		Test.getEventBus().deliver();
		startCalled = true;
		if (startException != null) {
			throw startException;
		}
		return Database.getQueryLocator('SELECT Id FROM User LIMIT 1');
	}
	
	protected override void doExecute(Database.BatchableContext bc, List<SObject> scope) {
		executeCalled = true;
		if (executeException != null) {
			throw executeException;
		}
	}
	
	protected override void doFinish(Database.BatchableContext bc) {
		finishCalled = true;
		if (finishException != null) {
			throw finishException;
		}
	}
}