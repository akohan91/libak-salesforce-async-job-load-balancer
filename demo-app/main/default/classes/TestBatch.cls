public with sharing class TestBatch extends BatchableJob {
	// To achieve a total failure rate of 50%, we adjust individual failure rates
	private final Double FAILURE_RATE = 0.206; // ~20.6% chance per method to get ~50% overall
	
	protected override Database.QueryLocator doStart(Database.BatchableContext batchContext) {
		// Generate random number and throw exception based on calculated rate
		Double randomValue = Math.random();
		if (randomValue < FAILURE_RATE) {
			throw new TestBatchException('Start method: Random failure occurred. Random value: ' + randomValue);
		}
		
		return Database.getQueryLocator('SELECT Id FROM Account');
	}

	protected override void doExecute(Database.BatchableContext batchContext, List<SObject> scope) {
		Datetime waitTo = Datetime.now().addSeconds(1);
		while (Datetime.now() < waitTo) {}
		
		// Generate random number and throw exception based on calculated rate
		Double randomValue = Math.random();
		if (randomValue < FAILURE_RATE) {
			throw new TestBatchException('Execute method: Random failure occurred. Random value: ' + randomValue);
		}
	}

	protected override void doFinish(Database.BatchableContext batchContext) {
		// Generate random number and throw exception based on calculated rate
		Double randomValue = Math.random();
		if (randomValue < FAILURE_RATE) {
			throw new TestBatchException('Finish method: Random failure occurred. Random value: ' + randomValue);
		}
	}
	
	public class TestBatchException extends Exception {}
}