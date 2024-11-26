trigger AsyncJobEventTrigger on AsyncJob__e (after insert) {
	AsyncJobEventService.instance.handleEvent(Trigger.new.get(0));
}