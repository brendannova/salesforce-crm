public class InformationRequestContactDisplay {
    private final InformationRequest__c ir;
    public String callName{get;set;}
    public String callNumber{get;set;}
    public String callOutcomes{get;set;}
    public Boolean visibleButton{get;set;}
    public Boolean visibleJoint{get;set;}

    public InformationRequestContactDisplay() {
        System.debug(ApexPages.currentPage().getParameters().get('irId'));
        ir = [SELECT 
              	Id,
              	ProviderSecret__c,
              	ProviderContact__c,
             	ProviderContact__r.Telephone__c,
              	FinancialProductFinServ__r.FinServ__PrimaryOwner__c,
              	FinancialProductFinServ__r.FinServ__JointOwner__c
              FROM InformationRequest__c WHERE Id = :ApexPages.currentPage().getParameters().get('irId')];
        callNumber = ir.ProviderContact__r.Telephone__c;
        visibleButton = true;
        if( ir.FinancialProductFinServ__r.FinServ__JointOwner__c == null ) {
            visibleJoint = false;
        } else {
        	visibleJoint = true;
        }
    }

    public InformationRequest__c getInfoReq() {
        return ir;
    }
    
    public PageReference save() {
        update ir;
        return null;
    }
    
    public PageReference postToChatter() {
        FeedItem feed = new FeedItem();
		feed.ParentId =  ir.Id;
        String message = datetime.now().format('dd/MM/yy') + ' -- ' + callNumber + ' -- ' + callName + '   |   ' + callOutcomes;
        feed.body = message;
        insert feed;
		visibleButton = false;
        callName = '';
        callOutcomes ='';
        return null;
    }
    
    public Account getPrimaryOwner(){
        InformationRequest__c ir = getInfoReq();
        return [SELECT 
                Id, 
                Name,
                PersonBirthdate,
                National_Insurance_Number__pc,
                FinServ__ShippingAddress__pc
                FROM Account WHERE Id =: ir.FinancialProductFinServ__r.FinServ__PrimaryOwner__c
               ];    
    }
    public Account getJointOwner(){
        InformationRequest__c ir = getInfoReq();
        if( ir.FinancialProductFinServ__r.FinServ__JointOwner__c == null ) {
            visibleJoint = false;
            return null;
        } else {
        return [SELECT 
                Id,
                Name,
                PersonBirthdate,
                National_Insurance_Number__pc 
                FROM Account WHERE Id =: ir.FinancialProductFinServ__r.FinServ__JointOwner__c
                ];   
        }
    }
    public ProviderContact__c getProviderContact(){
        InformationRequest__c ir = getInfoReq();
        return [SELECT Id, Name, Email__c, Telephone__c FROM ProviderContact__c WHERE Id =: ir.ProviderContact__c];    
    }
    

}