public class EmailInformationRequestUpdateTable {
    public String objectId{get;set;}
    public List<String> owners;
    public Map<String, List<IrUpdate>> outputs;

    public Map<String, List<IrUpdate>> getOutputs() {
        setOutputs(objectId);
        return outputs;
    }
    
    public List<String> getOwners() {
        setOutputs(objectId);
        return owners;
    }
    
    // Takes a list of data request updates and updates the output map from every owner to a list of their updates    
    public void setOutputs(String objectId) {
        List<IrUpdate> irs = setIrs(objectId);
        List<String> owners = new List<String>();
        Map<String, List<irUpdate>> returnMap = new Map<String, List<irUpdate>>();
        
        for ( irUpdate ir : irs ) {
            if ( !owners.contains(ir.name) ) {
                owners.add(ir.name);
            }
        }
        for (String s : owners) {
            List<irUpdate> tempList = new List<irUpdate>();
            for (irUpdate ir : irs ) {
                if ( ir.name == s ) {
                    tempList.add(ir);
                }
        	}
            returnMap.put(s, tempList); 
        }
        this.outputs = returnMap;
        this.owners = owners;
    }
        
    // Takes an object id for a piece of advice and returns a list of data request updates
    public List<irUpdate> setIrs(String objectId) {
        System.debug('in set irs');
        List<Advice__c> advList = [SELECT Id FROM Advice__c WHERE Advice_Household__c =: objectId AND (Advice_Status__c = 'Data gathering' OR Advice_Status__c = 'Risk call')];
        Set<Id> advIds = new Set<Id>(new Map<Id, Advice__c>(advList).keySet());
        List<InformationRequest__c> irs = [ SELECT Id, 
                                           FinancialProductFinServ__r.Public_Provider_Name__r.DeveloperName__c,
                                           FinancialProductFinServ__r.FinServ__JointOwner__c, 
                                           DateInformationRequestSent__c, 
                                           FinancialProductFinServ__r.FinServ__PrimaryOwner__r.AddressedName__pc,
                                           ComplaintStatus__c,
                                           FinancialProductFinServ__r.Company_Name__c,
                                           FinancialProductFinServ__r.Subtype__c,
                                           FinancialProductFinServ__r.Public_Provider_Name__r.Name,
                                           FinancialProductFinServ__r.FinServ__FinancialAccountNumber__c,
                                           Status__c,
                                           InformationRequestType__r.InformationSource__c,
                                           FirstExpectedReceiptDate__c,
                                           ExpectedReceiptDate__c,
                                           DateLastChased__c 
                                           FROM InformationRequest__c WHERE Advice__c IN :advIds ];
        
        String status;
        String message;
        String title;
        String role;
        String name;
        List<IrUpdate> irList = new List<IrUpdate>();
        
        for (InformationRequest__c r : irs) {  
            System.debug(r.ExpectedReceiptDate__c);
            // Set title
            if ( r.FinancialProductFinServ__r.Subtype__c == 'Direct Equity Holding' ) {
                title = r.FinancialProductFinServ__r.Company_Name__c + ' Shares';
            } else {
                title = r.FinancialProductFinServ__r.Public_Provider_Name__r.Name + ' ' + r.FinancialProductFinServ__r.Subtype__c;
            }
            
            // Set role and name
            if ( r.FinancialProductFinServ__r.FinServ__JointOwner__c == null ) {
                role = 'Client';
                name = r.FinancialProductFinServ__r.FinServ__PrimaryOwner__r.AddressedName__pc;
            } else {
                role = 'Joint';
                name = 'Joint';
            }
            
            // Set status and messages
            
            // Await advice progression
            if (r.Status__c == 'Awaiting advice progression') {
                status = 'On track';
                message = System.Label.EmailInformationRequestUpdateClientRequest;
                
            // Policy pre-reqs required
            } else if (r.Status__c == 'Awaiting policy pre-requisites') {
                String awaitDetails = '';
                if ( r.FinancialProductFinServ__r.FinServ__FinancialAccountNumber__c == '' ){
                    awaitDetails += 'provider, ';
                }
                if ( r.FinancialProductFinServ__r.Public_Provider_Name__r.DeveloperName__c == 'UNKNOWN') {
                    awaitDetails += 'policy number, ';
                }
                if( r.FinancialProductFinServ__r.Subtype__c.contains('Junior')&& r.FinancialProductFinServ__r.RegisteredContact__c == '') {
                    awaitDetails += 'registered contact, ';
                }
                awaitdetails = awaitDetails.substringBeforeLast(', ') + ' & ' + awaitDetails.substringAfterLast(', ');
                
                status = 'Action required';
                message = System.Label.EmailInformationRequestUpdateAwaitPreReqsPt1 + awaitDetails + System.Label.EmailInformationRequestUpdateAwaitPreReqsPt2;
                
                
                
            // Info request to be sent - differs by info source
            } else if (r.Status__c == 'Information request to be sent') {
                if (r.InformationRequestType__r.InformationSource__c == 'Client') {
                    status = 'On track';
                    message = System.Label.EmailInformationRequestUpdateClientRequest;
                    
                } else if (r.InformationRequestType__r.InformationSource__c == 'Third party provider') {
                    status = 'On track';
                    message = System.Label.EmailInformationRequestUpdatePrepRequest;
                    
                }
                
            // Awaiting initial information
            } else if (r.Status__c == 'Awaiting initial information') {
                
                // If info is from client
                if (r.InformationRequestType__r.InformationSource__c == 'Client') {
                    status = 'Action required';
                    message = System.Label.EmailInformationRequestUpdateChaseClient;
                    
                // If info is from third party
                } else if (r.InformationRequestType__r.InformationSource__c == 'Third party provider') {
                    
                    // Check if we have ever chased before
                    if( r.FirstExpectedReceiptDate__c == null ) {
                        status = 'On track';
                        message = System.Label.EmailInformationRequestUpdateChasing + ' ' + formatDate( r.DateInformationRequestSent__c) + '.';
                        
                    // If we have chased before...
                    } else {
                        
                        // Expected receipt date has passed
                        if( date.today() > r.ExpectedReceiptDate__c ) {
                            
                            // Complaint in progress
                            if( r.ComplaintStatus__c == 'Lodged') {
                                status = 'Off track';
                                message = System.Label.EmailInformationRequestUpdateComplaintLodged;
                                
                            // Complaint resolved, still chasing
                            } else if ( r.ComplaintStatus__c == 'Resolved') {
                                status = 'On track';
                                message = System.Label.EmailInformationRequestUpdateChasingPart1 + ' ' + formatDate(r.DateLastChased__c) + '. ' + r.FinancialProductFinServ__r.Public_Provider_Name__r.Name + ' ' + System.Label.EmailInformationRequestUpdateChasingPart2 + ' ' + formatDate(r.ExpectedReceiptDate__c) + '.';
                                
                            // No complaint made
                            } else {
                                status = 'Off track';
                                message = r.FinancialProductFinServ__r.Public_Provider_Name__r.Name + ' ' + System.Label.EmailInformationRequestUpdateOffTrack + ' ' + formatDate(r.ExpectedReceiptDate__c) + ' ' + System.Label.EmailInformationRequestUpdateOffTrackPt2;
                            }
                            
                            
                        // Expected receipt date in future
                        } else {
                            status = 'On track';
							message = System.Label.EmailInformationRequestUpdateChasingPart1 + ' ' + formatDate(r.DateLastChased__c) + '. ' + r.FinancialProductFinServ__r.Public_Provider_Name__r.Name + ' ' + System.Label.EmailInformationRequestUpdateChasingPart2 + ' ' + formatDate(r.ExpectedReceiptDate__c) + '.';                        
                        }  
                    }
                }
                
            // Information received
            } else if (r.Status__c == 'Checklist review') {
                if (r.InformationRequestType__r.InformationSource__c == 'Client') {
                    status = 'On track';
                    message = System.Label.EmailInformationRequestUpdateClientReceived;
                    
                } else if (r.InformationRequestType__r.InformationSource__c == 'Third party provider') {
                    status = 'On track';
                    message = System.Label.EmailInformationRequestUpdateInfoReceived;
                }
                
            // Checklist complete
            } else if (r.Status__c == 'Fund analysis') {
                status = 'Completed';
                message = System.Label.EmailInformationRequestUpdateComplete;
                
            // Completed
            } else if (r.Status__c == 'Complete' || r.Status__c == 'Ready for advice') {
                status = 'Completed';
                message = System.Label.EmailInformationRequestUpdateComplete;
                
            // Other
            } else {
                status = 'Off track';
                message = System.Label.EmailInformationRequestGeneric;
            }
            
            // Add data request update to collection of outputs
            if( status != null ) {
                irList.add(new irUpdate(title, message, status, role, name));
            }

        }
        
        irList.sort();
        return irList;
    }

    // Data request update class with custom sorting function
    public class irUpdate implements Comparable {
        public String title {get;set;}
        public String message {get;set;}
        public String status {get;set;}
        public String role {get;set;}
        public String name{get;set;}
        
        public irUpdate(String t, String m, String s, String r, String n) {
            title = t;
            message = m;
            status = s;
            role = r;
            name = n;
        }
        
        public Integer compareTo(Object compareTo){
            irUpdate compareToOwn = (irUpdate)compareTo;
            if(role == compareToOwn.role){
                if(role == compareToOwn.role){
                    if(name == compareToOwn.name){
                        return 0;
                    } else if(name < compareToOwn.name){
                        return -1;
                    } else {
                        return 1;
                    }
                } else if( role == 'Joint' && compareToOwn.role != 'Joint' ){
                    return -1;
                } else {
                    return 1;
                }
            } else if(role == 'Client' && compareToOwn.role != 'Client'){
                return -1;
            } else {
                return 1;
            }
        }
    }
    
    public String formatDate(Date d) {
        DateTime dt = DateTime.newInstance(d.year(), d.month(), d.day());
        return dt.format('d MMMMM yyyy');
    }
}