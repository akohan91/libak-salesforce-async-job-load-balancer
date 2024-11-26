public with sharing class QueueableJob implements Queueable, Finalizer, Database.AllowsCallouts {
	

	public void execute(QueueableContext context) {
		try {

		} catch (Exception exc) {
			
		} finally {
			System.attachFinalizer(this);
		}
	}
	
	public void execute(System.FinalizerContext context) {

	}
}