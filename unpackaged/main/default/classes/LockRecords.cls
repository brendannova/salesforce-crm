public class LockRecords {
    @InvocableMethod (label='Lock records')
    public Static void lockRecords(List<Id> listOfIdsToLock){
        Approval.lock(listOfIdsToLock);
        //for (Id idToLock : listOfIdsToLock){}
    }
}