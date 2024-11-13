public class UnlockRecords {
    @InvocableMethod (label='Unlock records')
    public Static void unlockRecords(List<Id> listOfIdsToUnock){
        Approval.unlock(listOfIdsToUnock);
        //for (Id idToLock : listOfIdsToLock){}
    }
}