@IsTest
public with sharing class FakeId {

	private Id fakeId;
	private SObjectType sObjectType;
	private DescribeSObjectResult sObjectDescribe;

	public FakeId(SObjectType sObjectType) {
		this.sObjectType = sObjectType;
		this.sObjectDescribe = sObjectType.getDescribe();
	}

	public String getFakeId() {
		if (this.fakeId == null) {
			Integer uniqueInt = Crypto.getRandomInteger();
			String unique = String.valueOf(uniqueInt > 0 ? uniqueInt : -uniqueInt);
			this.fakeId = this.sObjectDescribe.getKeyPrefix() + '0'.repeat(12 - unique.length()) + unique;
		}
		return this.fakeId;
	}
}