public with sharing class EmailFulfilmentNextSteps {
    public String objectId{get;set;}
    private Boolean activeHousehold = false;
    private Boolean othersFlag = false;
    private Boolean lumpSumFlag = false;
    private List<Recommendation__c> recommendations = new List<Recommendation__c>();
    private Map<String, ProductSummary> productSummaryMap = new Map<String, ProductSummary>();
    private Map<String, RecommendationSummary> recommendationSummaryMap = new Map<String, RecommendationSummary>();
    private List<EmailCategory> emailCategories = new List<EmailCategory>();
    private List<Recommendation__c> cancelRegularRecommendations = new List<Recommendation__c>();
    private List<Recommendation__c> employerRegularRecommendations = new List<Recommendation__c>();
    private Map<String, List<NextStepsAction>> categoryActionMap = new Map<String, List<NextStepsAction>>();
    private List<NextStepsAction> allNextSteps = new List<NextStepsAction>();
    private List<AdviceRecipient__c> recipients = new List<AdviceRecipient__c>();
    private Advice__c adviceRecord = new Advice__c();
    Boolean constructorRun = false;

    public void EmailFulfilmentNextStepsTableGroupedConstructor() {
        if(!constructorRun){
            constructorRun = true;
            System.debug('in constructor');
            if(String.isBlank(objectId)){
                objectId = ApexPages.currentPage().getParameters().get('objectId');
            }
            if (String.isNotBlank(objectId)) {
                // Get household status and set active flag
                adviceRecord = [SELECT Id, Suitability_meeting_status__c, Advice_Household__r.FinServ__Status__c FROM Advice__c WHERE Id = :objectId];
                if(adviceRecord.Advice_Household__r.FinServ__Status__c == 'Active'){
                    activeHousehold = true;
                }

                // Get recommendations
                recommendations = [SELECT Id, SourceLegacy__r.Subtype__c, SourceLegacy__r.TransferFormFormat__c, Employment__r.EmployerContributionsSetUpBy__c, ClientInstructions__c, Household__r.FinServ__Status__c, PrimaryOwner__r.FirstName, PrimaryOwner__r.AddressedName__pc, JointOwner__r.AddressedName__pc, JointOwner__c, JointOwner__r.FirstName, Employment__c,Employment__r.Name, PaidBy__c, DestinationName__c, DestinationLegacy__c, DestinationLegacy__r.Public_Provider_Name__r.Name, DestinationLegacy__r.FinServ__RecordTypeName__c, RecommendationType__c, RecommendationType__r.ReferenceName__c, Product__c, Product__r.ProductType__r.ReferenceName__c, Household__c, NonStandardActionInstruction__c FROM Recommendation__c WHERE Advice__c =: objectId AND Status__c = 'Accepted'];
                if(recommendations.isEmpty()){
                    // Throw exception
                    System.debug('ERROR: No recommendations found');
                } else {
                    
                    // Create product summary variables
                    ProductSummary psIsa = new ProductSummary('ISA', 0, 0, 'ISA');
                    ProductSummary psSipp = new ProductSummary('SIPP', 0, 0, 'SIPP');
                    ProductSummary psJsipp = new ProductSummary('JSIPP', 0, 0, 'Junior SIPP');
                    ProductSummary psJisa = new ProductSummary('JISA', 0, 0, 'Junior ISA');
                    ProductSummary psGia = new ProductSummary('GIA', 0, 0, 'GIA');
                    ProductSummary psOb = new ProductSummary('OFFSHORE_BOND', 0, 0, 'Offshore Bond');
                    ProductSummary psCisa = new ProductSummary('CASH_ISA', 0, 0, 'Cash ISA');

                    // Create recommendation summary variables
                    RecommendationSummary recOpenNonPension = new RecommendationSummary('OPEN_PRODUCT_NON_PENSION', 0);
                    RecommendationSummary recCancelReg = new RecommendationSummary('CANCEL_REGULAR', 0);
                    RecommendationSummary recTransfer = new RecommendationSummary('TRANSFER', 0);
                    RecommendationSummary recTransferPost = new RecommendationSummary('TRANSFER_VIA_POST', 0);
                    RecommendationSummary recRegular = new RecommendationSummary('REGULAR_CLIENT', 0);
                    RecommendationSummary recEmployerRegular = new RecommendationSummary('EMPLOYER_REGULAR', 0);
                    RecommendationSummary recOpen = new RecommendationSummary('OPEN_PRODUCT', 0);
                    
                    // Loop recommendations to create sublists and product counts
                    for ( Recommendation__c rec : recommendations ) {
                        if ( rec.RecommendationType__r.ReferenceName__c == 'LUMP_SUM' && !lumpSumFlag) {
                            lumpSumFlag = true;
                        } else if ( rec.RecommendationType__r.ReferenceName__c == 'CLIENT_ACTION' && !othersFlag) {
                            othersFlag = true;
                        } else if ( rec.RecommendationType__r.ReferenceName__c == 'OPEN_PRODUCT' ) {
                            recOpen.count++;
                            if ( rec.Product__r.ProductType__r.ReferenceName__c == 'SSISA' ) {
                                psIsa.productCount++;
                                recOpenNonPension.count++;
                                recOpen.count++;
                            } else if ( rec.Product__r.ProductType__r.ReferenceName__c == 'JISA' ) {
                                psJisa.productCount++;
                                recOpenNonPension.count++;
                                recOpen.count++;
                            } else if ( rec.Product__r.ProductType__r.ReferenceName__c == 'GIA' ) {
                                psGia.productCount++;
                                recOpenNonPension.count++;
                                recOpen.count++;
                            } else if ( rec.Product__r.ProductType__r.ReferenceName__c == 'OFFSHORE_BOND' ) {
                                psOb.productCount++;
                                recOpenNonPension.count++;
                                recOpen.count++;
                            } else if ( rec.Product__r.ProductType__r.ReferenceName__c == 'SIPP' ){
                                psSipp.productCount++;
                                recOpen.count++;
                            } else if ( rec.Product__r.ProductType__r.ReferenceName__c == 'JSIPP' ){
                                psJsipp.productCount++;
                                recOpen.count++;
                            }
                        } else if ( rec.RecommendationType__r.ReferenceName__c == 'CANCEL_EXISTING_REGULAR' ){
                            recCancelReg.count++;
                            cancelRegularRecommendations.add(rec);
                        } else if (rec.RecommendationType__r.ReferenceName__c == 'EXTERNAL_TRANSFER_IN' ) {
                                if ( rec.Product__r.ProductType__r.ReferenceName__c == 'SIPP' ) {
                                    psSipp.transferCount++;
                                } else if ( rec.SourceLegacy__r.Subtype__c == 'Cash ISA') {
                                    psCisa.transferCount++;
                                }else if ( rec.Product__r.ProductType__r.ReferenceName__c == 'SSISA' ) {
                                    psIsa.transferCount++;
                                } else if ( rec.Product__r.ProductType__r.ReferenceName__c == 'JISA' ) {
                                    psJisa.transferCount++;
                                } else if ( rec.Product__r.ProductType__r.ReferenceName__c == 'JSIPP' ) {
                                    psJsipp.transferCount++;
                                } else if ( rec.Product__r.ProductType__r.ReferenceName__c == 'GIA' ) {
                                    psGia.transferCount++;
                                } 
                            if ( rec.SourceLegacy__r.TransferFormFormat__c == 'DocuSign' ) {
                                recTransfer.count++;
                            } else {
                                recTransferPost.count++; 
                            }
                        } else if (rec.RecommendationType__r.ReferenceName__c == 'REGULAR' ) {
                            if (rec.PaidBy__c == 'Employer' ) {
                                recRegular.count++;
                            } else {

                            }
                        }
                    }

                    // Add product and recommendation summary items to the map
                    productSummaryMap.put('ISA', psIsa);
                    productSummaryMap.put('JISA', psJisa);
                    productSummaryMap.put('GIA', psGia);
                    productSummaryMap.put('OFFSHORE_BOND', psOb);
                    productSummaryMap.put('SIPP', psSipp);
                    productSummaryMap.put('JSIPP', psJsipp);
                    productSummaryMap.put('CASH_ISA', psCisa);
                    recommendationSummaryMap.put('OPEN_PRODUCT_NON_PENSION', recOpenNonPension);
                    recommendationSummaryMap.put('OPEN_PRODUCT', recOpen);
                    recommendationSummaryMap.put('CANCEL_REGULAR', recCancelReg);
                    recommendationSummaryMap.put('TRANSFER', recTransfer);
                    recommendationSummaryMap.put('EMPLOYER_REGULAR', recEmployerRegular);
                    recommendationSummaryMap.put('REGULAR_CLIENT', recRegular);
                    recommendationSummaryMap.put('TRANSFER_VIA_POST', recTransferPost);
                    System.debug('open prods: ' + recOpen.count);
                }
                Map<String, EmailCategory> emailCategoriesAllMap = new Map<String, EmailCategory>();
                emailCategoriesAllMap.put('INFORMATION', new EmailCategory('INFORMATION', 'What We\'ll Do Next'));
                emailCategoriesAllMap.put('BANK_DETAILS', new EmailCategory('BANK_DETAILS', 'Bank Details'));
                emailCategoriesAllMap.put('FORMS', new EmailCategory('FORMS', 'Forms to Sign'));
                emailCategoriesAllMap.put('CANCEL_REGULARS', new EmailCategory('CANCEL_REGULARS', 'Regular Contributions with Other Providers to Cancel'));
                emailCategoriesAllMap.put('OTHER', new EmailCategory('OTHER', 'Other'));
                for(EmailCategory ec : emailCategoriesAllMap.values()){
                    categoryActionMap.put(ec.id, new List<NextStepsAction>());
                }
                
                System.debug('recs: ' + recommendations);
                if(!recommendations.isEmpty()){
                    // Information section
                    getnewProds();
                    getLumpSum();
                    getRegulars();
                    // Bank details section
                    getBankDetails();
                    getemployerBank();
                    // Forms section
                    getTransfers();
                    getSipps();
                    getCashIsaTransfers();
                    getcancelReg();
                    getemployerReg();
                    geteow();
                    getOthers();
                    for(NextStepsAction ns : allNextSteps){
                        categoryActionMap.get(ns.category).add(ns);
                    }
                }
                
                for(String key : categoryActionMap.keySet()){
                    if(categoryActionMap.get(key).size() == 0){
                        categoryActionMap.remove(key);
                    } else {
                        emailCategories.add(emailCategoriesAllMap.get(key));
                    }
                }
            }
        }   
    }

    private void getRecipients(){
        recipients = [SELECT Id, Person__r.BankdetailsStatus__c, Person__r.FirstName, Person__r.AddressedName__pc, AcceptedAdvice__c FROM AdviceRecipient__c WHERE Advice__c = :objectId AND Advised__c = 'Yes'];
    }

    public String getAcceptanceString(){
        String outputString = '';
        if(recipients.isEmpty()){
            getRecipients(); 
        }
        if(!recipients.isEmpty()){
            Boolean allAccepted = true;
            String awaitingList = '';
            String acceptedList = '';
            for ( AdviceRecipient__c advrec : recipients ) {
                if ( advrec.AcceptedAdvice__c == 'Still considering' ) {
                    allAccepted = false;
                    awaitingList+= advrec.Person__r.AddressedName__pc;
                } else if ( advrec.AcceptedAdvice__c == 'Some or all advice accepted' ){
                    acceptedList += advrec.Person__r.AddressedName__pc;
                }
            }
            if (!allAccepted) {
                outputString = acceptedList + ', many thanks for confirming your agreement to go ahead. ' + awaitingList + ', please review our recommendations and send us confirmation of your acceptance at your earliest convenience.';
            } else {
                outputString = 'Many thanks for confirming your agreement to go ahead.';
            }
        }
        return outputString;
    }
    
    public String getOutroString(){
        String outputString = '';
        if(recipients.isEmpty()){
            getRecipients(); 
        }
        if(!recipients.isEmpty()){
            Boolean allReceived = true;
            for ( AdviceRecipient__c advrec : recipients ) {
                if ( advrec.Person__r.BankDetailsStatus__c != 'Submitted' ) {
                    allReceived = false;   
                }
            }
            if (!allReceived) {
                outputString = 'You can share all of your bank account details with us directly through your profile, please see the link below:'
                    + ' <p>' + '<a href="https://portal.novawm.com/profile/bank-accounts/"> My/Our bank account details</a>'
                    + ' </p> <p>' + 'Please let me know if you have any issues accessing your profile.'
                    + ' </p> <p>' + 'We will never ask you to share your bank details with us via email. Instead, we will only ever ask you to share your bank details with us in a secure way. If you are ever unsure of a request, please give us a call to confirm.'
                    ;
            }
        }
        return outputString;
    }

    public List<EmailCategory> getEmailCategories(){
        EmailFulfilmentNextStepsTableGroupedConstructor();  
        return emailCategories;
    }

    public Map<String, List<NextStepsAction>> getCategoryActionMap() {
        return categoryActionMap;
    }

    public void getBankDetails() {
        // If this is an onboarding household, we need to request bank details
        if ( !activeHousehold ) {
            String titleString = System.Label.EmailNextStepsBankTitle;
            String messageString = System.Label.EmailNextStepsBankMessage;
            if(recipients.isEmpty()){
                getRecipients(); 
            }
            if( recipients.size() > 1 ) {
                messageString += ' ' + System.label.EmailNextStepsBankMessageJointAddition;
            }
            allNextSteps.add(new NextStepsAction(titleString, messageString, 'Action required', 'BANK_DETAILS'));
        }
    }   

    public void getnewProds() {
        String status = 'On track';
        String category = 'INFORMATION';
        Integer openProductCount = this.recommendationSummaryMap.get('OPEN_PRODUCT').count;
        if ( openProductCount > 0 ) {
            String titleString = 'Your new ';
            String messageString;
            
            // Produce the title string
            List<String> productTypes = new List<String>{'GIA', 'ISA', 'SIPP', 'JISA', 'JSIPP', 'OFFSHORE_BOND'};
            String comma = '';
            for(String productType : productTypes){
                if(this.productSummaryMap.get(productType).productCount == 1){
                    titleString += comma + this.productSummaryMap.get(productType).friendlyName;
                    comma = ', ';
                } else if (this.productSummaryMap.get(productType).productCount > 1){
                    titleString += comma + this.productSummaryMap.get(productType).friendlyName + 's';
                    comma = ', ';
                }
            }
            if ( titleString.contains(', ') ) {
                titleString = titleString.subStringBeforeLast(', ') +  ' & ' + titleString.subStringAfterLast(', ');
            }

            // Message string
            if ( openProductCount == 1 ) {
                if( activeHousehold ){
                    messageString = System.label.EmailNextStepsOpenProduct;
                } else {
                    messageString = System.Label.EmailNextStepsOpenProductBankNeeded;
                }
            } else {
                if( activeHousehold ){
                    messageString = System.Label.EmailNextStepsOpenProducts;
                } else {
                    messageString = System.Label.EmailNextStepsOpenProductsBankNeeded;
                }
            }
            // Delete custom label if not used anywhere else:System.label.EmailNextStepsAccountPlural; //
            // Delete custom label if not used anywhere else:System.label.EmailNextStepsAccountSingular;
            allNextSteps.add(new NextStepsAction(titleString, messageString, status, category));
        }
    }

    public void getLumpSum(){
        if ( lumpSumFlag ) {
            String status = 'On track';
            String category = 'INFORMATION';
            String title;
            STring message;
            if( this.recommendationSummaryMap.get('OPEN_PRODUCT').count > 0 ) {
                title = 'Topping up your new accounts';
            	message = 'Once your new accounts are opened, we\'ll send you payment instructions.';
            } else {
                title = 'Topping up your accounts';
            	message = 'We will send you payment instructions shortly.';
            }
            allNextSteps.add(new NextStepsAction(title, message, status, category));
        }
    }

    public void getRegulars(){
        if ( recommendationSummaryMap.get('REGULAR_CLIENT').count > 0 ) {
            String status = 'On track';
            String category = 'INFORMATION';
            String title = 'Regular deposits';
            String message = 'We\'ll set up the direct debits when we have your bank details.';
            allNextSteps.add(new NextStepsAction(title, message, status, category));
        }
    }

    public void getSipps() {
        Integer sippCount = this.productSummaryMap.get('SIPP').productCount;
        if(sippCount > 0){ 
            String titleString;
            String messageString;   
            if ( sippCount == 1 ) {
                titleString = System.label.EmailNextStepsSippTitleSingular;
                messageString = System.label.EmailNextStepsSippMessageSingular;
            } else if ( sippCount > 1 ) {
                titleString = System.label.EmailNextStepsSippTitlePlural;
                messageString = System.label.EmailNextStepsSippMessagePlural;
            }
            allNextSteps.add(new NextStepsAction(titleString, messageString, 'Action required', 'FORMS'));
        }
    }

    public void getTransfers() {
        String messageString;
        String titleString = 'Your ';
        if ( recommendationSummaryMap.get('TRANSFER').count + recommendationSummaryMap.get('TRANSFER_VIA_POST').count > 0 ) {
            List<String> productTypes = new List<String>{'ISA', 'JISA', 'GIA', 'SIPP', 'CASH_ISA'};
            String comma = '';
            for(String productType : productTypes){
                if(this.productSummaryMap.get(productType).transferCount > 0){
                    titleString += comma + this.productSummaryMap.get(productType).friendlyName;
                    comma = ', ';
                }
            }
            if ( titleString.contains(', ') ) {
                titleString = titleString.subStringBeforeLast(', ') +  ' & ' + titleString.subStringAfterLast(', ');
            }
            if ( recommendationSummaryMap.get('TRANSFER').count == 1 && recommendationSummaryMap.get('TRANSFER_VIA_POST').count == 0) {
                titleString = titleString + ' transfer';
                messageString = System.label.EmailNextStepsTransfersMessageT1P0;
            } else if ( recommendationSummaryMap.get('TRANSFER').count > 1 && recommendationSummaryMap.get('TRANSFER_VIA_POST').count == 0 ) {
                titleString = titleString + ' transfers';
                messageString = System.label.EmailNextStepsTransfersMessageTMP0;
            } else if ( recommendationSummaryMap.get('TRANSFER').count == 1 && recommendationSummaryMap.get('TRANSFER_VIA_POST').count == 1 ) {
                titleString = titleString + ' transfers';
                messageString = System.label.EmailNextStepsTransfersMessageT1P1;
            } else if ( recommendationSummaryMap.get('TRANSFER').count > 1 && recommendationSummaryMap.get('TRANSFER_VIA_POST').count > 1 ) {
                titleString = titleString + ' transfers';
                messageString = System.label.EmailNextStepsTransfersMessageTMPM;
            } else if ( recommendationSummaryMap.get('TRANSFER').count == 0 && recommendationSummaryMap.get('TRANSFER_VIA_POST').count == 1 ) {
                titleString = titleString + ' transfer';
                messageString = System.label.EmailNextStepsTransfersMessageT0P1;
            } else if ( recommendationSummaryMap.get('TRANSFER').count == 0 && recommendationSummaryMap.get('TRANSFER_VIA_POST').count > 1 ) {
                titleString = titleString + ' transfers';
                messageString = System.label.EmailNextStepsTransfersMessageT0PM;
            } else if ( recommendationSummaryMap.get('TRANSFER').count == 1 && recommendationSummaryMap.get('TRANSFER_VIA_POST').count > 1 ) {
                titleString = titleString + ' transfers';
                messageString = System.label.EmailNextStepsTransfersMessageT1PM;
            } else if ( recommendationSummaryMap.get('TRANSFER').count > 1 && recommendationSummaryMap.get('TRANSFER_VIA_POST').count == 1 ) {
                titleString = titleString + ' transfers';
                messageString = System.label.EmailNextStepsTransfersMessageTMP1;
            }
            
            allNextSteps.add(new NextStepsAction(titleString, messageString, 'Action required', 'FORMS'));
        }
    }
    
    public void getCashIsaTransfers() {
        Integer cashIsaCount = productSummaryMap.get('CASH_ISA').transferCount;
        if(cashIsaCount > 0){
            String category = 'OTHER';
            String status = 'Action required';
            String messageString;
            String titleString;
            if( cashIsaCount == 1 ) {
                messageString = System.label.EmailNextStepsCashIsaMessageSingle;
                titleString = System.label.EmailNextStepsCashIsaTitleSingle;
            } else {
                messageString = System.label.EmailNextStepsCashIsaMessagePlural;
                titleString = System.label.EmailNextStepsCashIsaTitlePlural;      
            }
            allNextSteps.add(new NextStepsAction(titleString, messageString, status, category));
        }
    }

    public void getcancelReg() {
        Integer cancelRegsCount = recommendationSummaryMap.get('CANCEL_REGULAR').count;
        // Change copy if non-presented
        if((cancelRegsCount >= 1)){
            String category = 'OTHER';
            String status = 'Action required';
            String titleString = '';
            String messageString = '';
            String productList = ' ';
            String clientName;
            for(Recommendation__c rec : cancelRegularRecommendations){
                if ( rec.JointOwner__c == null ) {
                    clientName = rec.PrimaryOwner__r.AddressedName__pc + '\'s ';
                } else {
                    clientName = 'your joint ';
                }
                productList = productList + clientName + rec.DestinationLegacy__r.Public_Provider_Name__r.Name + ' ' + rec.DestinationLegacy__r.FinServ__RecordTypeName__c + ', ';
            }
            if ( cancelRegsCount == 1 ) {
                productList = productList.subStringBeforeLast(', ');
                titleString = System.label.EmailNextStepsCancelRegularTitleSingle;
                if( this.adviceRecord.Suitability_meeting_status__c == 'Non-presented') {
                    messageString = System.label.EmailNextStepsCancelRegularPart1SingleNonPresented + productList + System.label.EmailNextStepsCancelRegularPart2;
                } else {
                    messageString = System.label.EmailNextStepsCancelRegularPart1Single + productList + System.label.EmailNextStepsCancelRegularPart2;
                }
            } else if ( cancelRegsCount > 1 ) {
                titleString = System.label.EmailNextStepsCancelRegularTitlePlural;
                productList = productList.subStringBeforeLast(', ');
                productList = productList.subStringBeforeLast(', ')+ ' & ' + productList.subStringAfterLast(', ');
                if( this.adviceRecord.Suitability_meeting_status__c == 'Non-presented') {
                    messageString = System.label.EmailNextStepsCancelRegularPart1PluralNonPresented + productList + System.label.EmailNextStepsCancelRegularPart2;
                } else {
                    messageString = System.label.EmailNextStepsCancelRegularPart1Plural + productList + System.label.EmailNextStepsCancelRegularPart2;
                }            }
            allNextSteps.add(new NextStepsAction(titleString, messageString, status, category));
        }  
    }

    public void getemployerBank() {
        String titleString = '';
        String messageString = '';
        for ( Recommendation__c rec : recommendations ) {
            if ( rec.PaidBy__c == 'Employer' ) {
                if ( !employerBankdetails ( rec.Employment__c )) {
                    titleString = System.label.EmailNextStepsEmployerBankTitle;
                    if ( rec.Employment__r.EmployerContributionsSetUpBy__c == 'Client') {
                        messageString = System.label.EmailNextStepsEmployerBankClient;
                    } else {
                        messageString = System.label.EmailNextStepsEmployerBankHr;
                    }
                }
            }
        }
        if(titleString != ''){
            allNextSteps.add(new NextStepsAction(titleString, messageString, 'Action required', 'BANK_DETAILS'));
        }
    }

    // The query within this is called from within a loop in the method above. Refactoring is needed. 
    public Boolean employerBankDetails( String employerId ) {
        Boolean output;
        FinServ__Employment__c employer = [SELECT Id, BankAccountStatus__c from FinServ__Employment__c Where Id =: employerId];
        if ( employer.BankAccountStatus__c == 'Submitted' ) {
            output = true;
        } else {
            output = false;
        }
        return output;
    }
    
    public void getemployerReg() {
        List<NextStepsAction> outputList = new list<NextStepsAction>();
        String message = System.label.EmailNextStepsEmployerRegularMessage;
        if(recommendationSummaryMap.get('EMPLOYER_REGULAR').count > 0){
            for ( Recommendation__c rec : employerRegularRecommendations ) {
                String title = rec.PrimaryOwner__r.AddressedName__pc + System.label.EmailNextStepsEmployerRegularTitlePartial + rec.Employment__r.Name;
                outputList.add(new NextStepsAction(title, message, 'Action required', 'OTHER'));
            }
            allNextSteps.addAll(outputList);
        }
    }
    
    public void geteow() {
        Integer eowCount = 0;
        String productList = '';
        String titleString = '';
        String messageString = '';
        String clientName;
        for ( Recommendation__c rec : recommendations ) {
            if ( rec.RecommendationType__r.ReferenceName__c == 'UPDATE_EOW' ) {
                if ( rec.JointOwner__c == null ) {
                    clientName = rec.PrimaryOwner__r.AddressedName__pc + '\'s ';
                } else {
                    clientName = 'your joint ';
                }
                eowCount = eowCount + 1; 
                productList = productList + ', ' + clientName + rec.DestinationLegacy__r.Public_Provider_Name__r.Name + ' ' + rec.DestinationLegacy__r.FinServ__RecordTypeName__c;
                titleString = 'Your ' + rec.DestinationLegacy__r.Public_Provider_Name__r.Name + ' ' + rec.DestinationLegacy__r.FinServ__RecordTypeName__c +' Expression of Wish update';
            }
        }
        if(eowCount > 0){
            if ( eowCount == 1 ) {
                titleString = System.label.EmailNextStepsEowUpdateTitleSingle;
                messageString = System.label.EmailNextStepsEowUpdateMessageSingle;
            } else if ( eowCount > 1 ) {
                productList = productList.replaceFirst(', ', ' ');
                productList = productList.subStringBeforeLast(', ') + ' and ' + productList.subStringAfterLast(', ');
                titleString = System.label.EmailNextStepsEowUpdateTitlePlural;
                messageString = System.label.EmailNextStepsEowUpdateMessagePluralPart1 + productList + System.label.EmailNextStepsEowUpdatePluralPart2;        
            }
            allNextSteps.add(new NextStepsAction(titleString, messageString, 'Action required', 'FORMS'));
        }
    }
    
    public void getOthers() {
        String titleString = '';
        String messageString = '';
        List<NextStepsAction> outputList = new List<NextStepsAction>();
        for ( Recommendation__c rec : recommendations ) {
            if ( rec.RecommendationType__r.ReferenceName__c == 'CLIENT_ACTION' ) {
                if ( rec.Destinationlegacy__c == null ) {
                    titleString = rec.PrimaryOwner__r.AddressedName__pc ;
                    messageString = rec.ClientInstructions__c;
                } else {
                    titleString = rec.DestinationName__c;
                    messageString = rec.ClientInstructions__c;
                }
                outputList.add(new NextStepsAction(titleString, messageString, 'Action required', 'OTHER'));
            }
        }
        if(outputList.size() > 0){
            allNextSteps.addAll(outputList);
        }
    }

    // ==== All classes reviewed === //    
    
    // Used to summarise the recommendations across different types of products
    public class ProductSummary {
        public String productType {get;set;}
        public Integer productCount {get;set;}
        public Integer transferCount {get;set;}
        public String friendlyName {get;set;}
        public ProductSummary(String pt, Integer pc, Integer tc, String fn){
            productType = pt;
            productCount = pc;
            transferCount = tc;
            friendlyName = fn;
        }
    }

    // Used to summarise the information across different types of recommendations
    public class RecommendationSummary {
        public String recommendationSummaryType {get;set;} // Does not necessarily map to 
        public Integer count {get;set;}
        public RecommendationSummary(String rt, Integer c){
            recommendationSummaryType = rt;
            count = c;
        }
    }

    // Used to track the categories we want the next step actions broken into for the email presentation
    public class EmailCategory{
        public String id {get;set;}
        public String label {get;set;}
        public EmailCategory(String i, String l){
            id = i;
            label = l;
        }
    }

    // The specific actions we want to display to the customer in the email 
    public class NextStepsAction {
        public String title {get;set;}
        public String message {get;set;}
        public String status {get;set;}
        public String category {get;set;}
        public NextStepsAction(String t, String m, String s, String c){
            title = t;
            message = m;
            status = s;
            category = c;
        }
    }
}