/**
 * Test implementation of QueueableJob for testing
 */
@IsTest
public class MockQueueableJob extends QueueableJob {
	public Boolean executeCalled = false;
	public Exception exceptionToThrow;
	
	protected override void doExecute(QueueableContext context) {
		executeCalled = true;
		if (exceptionToThrow != null) {
			throw exceptionToThrow;
		}
	}

	
	@SuppressWarnings('PMD.EmptyStatementBlock')
	override protected void attachFinalizer() {
		// don't attach finalizer to test context
	}
}