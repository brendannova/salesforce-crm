trigger UserTrigger on User (before insert, before update) {
    UserTriggerHelper helper = new UserTriggerHelper(Trigger.newMap);
}