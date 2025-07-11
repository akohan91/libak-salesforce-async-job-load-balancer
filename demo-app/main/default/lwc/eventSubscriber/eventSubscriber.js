import { LightningElement } from 'lwc';
import { subscribe, unsubscribe } from 'lightning/empApi';

const START_FROM_THE_MOST_RECENT_EVENT = -1;

export default class EventSubscriber extends LightningElement {
	caseAssignmentEventSubscription;
	connectedCallback() {
		this.subscribe();
	}

	async subscribe() {
		try {
			console.log('test')
			const eventHandler = ({data}) => {
				console.log(data.payload.Action__c, `
		Payload: ${data.payload.Payload__c};
		AsyncJobId__c: ${data.payload.AsyncJobId__c};
		JobRequestTypeId__c: ${data.payload.JobRequestTypeId__c};
		JobRequestId__c: ${data.payload.JobRequestId__c};`);
			}
			const response = await subscribe( '/event/AsyncJob__e', START_FROM_THE_MOST_RECENT_EVENT, eventHandler);
			console.log('response',response);
			
			this.caseAssignmentEventSubscription = response;
		} catch (error) {
			console.error(error);
		}
	}
}