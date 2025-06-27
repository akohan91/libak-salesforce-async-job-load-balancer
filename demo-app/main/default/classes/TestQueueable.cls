public with sharing class TestQueueable extends QueueableJob{
	override public void doExecute(System.QueueableContext context) {
		Datetime waitTo = Datetime.now().addSeconds(8);
		while (Datetime.now() < waitTo) {}
		// Integer i = 10 / 0;
	}
}