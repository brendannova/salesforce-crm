trigger UserTrigger on User (before insert, before update) {
    new UserTriggerHandler().run();
}