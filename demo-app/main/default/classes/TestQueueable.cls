public with sharing class TestQueueable extends QueueableJob{
	// Since there's only one method, 50% failure rate directly applies
	private final Double FAILURE_RATE = 0.5; // 50% chance of failure
	
	override public void doExecute(System.QueueableContext context) {
		Datetime waitTo = Datetime.now().addSeconds(1);
		while (Datetime.now() < waitTo) {}
		
		// Generate random number and throw exception in 50% of executions
		Double randomValue = Math.random();
		if (randomValue < FAILURE_RATE) {
			throw new TestQueueableException('Random failure occurred. Random value: ' + randomValue);
		}
	}
	
	public class TestQueueableException extends Exception {}
}