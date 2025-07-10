/**
 * This script contains things that should be run on a daily basis 
 * to monitor for and resolve known issues that exist in Salesforce
 */

// Run to identify instances of this
List<Advice__c> records = [SELECT Id, advice_household__c, (SELECT Id from Tasks WHERE OW_task_information_name__c = 'chase_recommendation_acceptance' AND IsClosed = false), (SELECT Id, Status__c from Recommendation__r WHERE Status__c = 'Awaiting decision') FROM Advice__c WHERE AdvicePresented__c = true ORDER BY Advice_status__c ASC, LastModifiedDate DESC];
Integer i = 0;
for(Advice__c record : records){
    if(record.Tasks.isEmpty() && !record.Recommendation__r.isEmpty() && i < 5){
        i++;
        System.debug(record.Id);
    }    
}
System.debug(i + ' missing tasks');

// Run to resolve, if i > 0 
List<Advice__c> records = [SELECT Id, advice_household__c, (SELECT Id from Tasks WHERE OW_task_information_name__c = 'chase_recommendation_acceptance' AND IsClosed = false), (SELECT Id, Status__c from Recommendation__r WHERE Status__c = 'Awaiting decision') FROM Advice__c WHERE AdvicePresented__c = true ORDER BY Advice_status__c ASC, LastModifiedDate DESC];
Integer i = 0;
for(Advice__c record : records){
    if(record.Tasks.isEmpty() && !record.Recommendation__r.isEmpty() && i < 5){
        System.debug('AdviceId: ' + record.Id + ' | HouseholdId: ' + record.Advice_household__c);
        Map<String, Object> params = new Map<String, Object>();
        params.put('related_advice_id', record.Id);
        params.put('what_id', record.Id);
        params.put('household_id', record.Advice_household__c);
        params.put('task_type', 'chase_recommendation_acceptance');
        
        // Instantiate and start the Flow
        Flow.Interview.OW_task_create_from_task_information yourFlow = new Flow.Interview.OW_task_create_from_task_information(params);
        yourFlow.start();
        i++;
    }    
}
System.debug(i + ' tasks created');

// Migrate Chatter for IRs from LOAs
List<LOA__c> loas = [SELECT Id, 
                        (SELECT Id, ParentId, Type, CreatedById, CreatedDate, LastModifiedDate, Title, Body, LinkUrl, IsRichText, RelatedRecordId, InsertedById, NetworkScope, Visibility, BestCommentId, 
                         (SELECT Id, FeedItemId, ParentId, CreatedById, CreatedDate, SystemModstamp, Revision, LastEditById, LastEditDate, CommentBody, InsertedById, CommentType, RelatedRecordId, IsRichText, IsVerified, HasEntityLinks, Status, ThreadParentId, ThreadLevel, ThreadChildrenCount, ThreadLastUpdatedDate 
                          FROM FeedComments) 
                         FROM Feeds), 
                        (SELECT Id FROM InformationRequests__r ORDER BY CreatedDate ASC)
                        FROM LOA__c 
                        WHERE MainLoaStatus__c = 'Replaced' AND ChatterPostsMigrated__c = false LIMIT 100];
Map<Id, FeedItem> oldNewFeedItemMap = new Map<Id, FeedItem>();
Map<Id, List<FeedComment>> oldfeedItemCommentMap = new Map<Id, List<FeedComment>>();
for(LOA__c loa : loas){
    loa.ChatterPostsMigrated__c = true;
    for(LOA__Feed loaPost : loa.Feeds){
        oldfeedItemCommentMap.put(loaPost.Id, loaPost.FeedComments);
        FeedItem newPost = new FeedItem(
            Body = loaPost.Body,
            CreatedById = loaPost.CreatedById,
            CreatedDate = loaPost.CreatedDate,
            IsRichText = loaPost.IsRichText,
            LinkUrl = loaPost.LinkUrl,
            ParentId = loa.InformationRequests__r[0].Id,
            Title = loaPost.Title,
            Type = loaPost.Type,
            Visibility = loaPost.Visibility
        );
        oldNewFeedItemMap.put(loaPost.Id, newPost);
        
    }
}
insert oldNewFeedItemMap.values();
List<FeedComment> newFeedComments = new List<FeedComment>();
for(Id loaPostId : oldNewFeedItemMap.keySet()){
    List<FeedComment> comments = oldfeedItemCommentMap.get(loaPostId);
    for(FeedComment comment : comments){
        FeedComment newComment = new FeedComment(
            CommentBody = comment.CommentBody,
            CommentType = comment.CommentType,
            CreatedById = comment.CreatedById,
            CreatedDate = comment.CreatedDate,
            FeedItemId = oldNewFeedItemMap.get(loaPostId).Id,
            IsRichText = comment.IsRichText,
            LastEditById = comment.LastEditById,
            LastEditDate = comment.LastEditDate,
            Revision = comment.Revision,
            Status = comment.Status
        );
        newFeedComments.add(newComment);
    }
}
insert newFeedComments;
update loas;
System.debug(oldNewFeedItemMap.size());
System.debug(newFeedComments.size());
System.debug(loas.size());


// Create RTQ task
List<Advice__c> records = [SELECT Id, Advice_household__c, Advice_status__c, RtqStatus__c, (SELECT Id from Tasks WHERE OW_task_information_name__c = 'ADVICE_REFRESH_RTQ' AND IsClosed = false) FROM Advice__c WHERE Advicetype__r.IsOnboarding__c = false AND Advice_status__c IN ('Data gathering','Data analysis', 'Risk call', 'Suitability in progress', 'Prepare advice') AND RtqStatus__c IN ('Not started','In progress') ORDER BY Advice_status__c ASC, RtqStatus__c ASC];
Integer i = 0;
for(Advice__c record : records){
    if(record.Tasks.isEmpty()){
        Map<String, Object> params = new Map<String, Object>();
        params.put('related_advice_id', record.Id);
        params.put('what_id', record.Id);
        params.put('household_id', record.Advice_household__c);
        params.put('task_type', 'ADVICE_REFRESH_RTQ');
        
        // Instantiate and start the Flow
        Flow.Interview.OW_task_create_from_task_information yourFlow = new Flow.Interview.OW_task_create_from_task_information(params);
        yourFlow.start();
        i++;
    }    
}
System.debug(i + ' tasks created');