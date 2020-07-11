public with sharing class CloneClass {


    @AuraEnabled(cacheable=true)
     public static List<OptionWrapper> getAllObjects(){
        List<OptionWrapper> sobjectname = new List<OptionWrapper>();
        List<String> sObjectList = new List<String>();
        for(Schema.SObjectType objTyp : Schema.getGlobalDescribe().Values()){
            Schema.DescribeSObjectResult res = objTyp.getDescribe();
            if(!objTyp.getDescribe().getName().containsignorecase('history') && !objTyp.getDescribe().getName().containsignorecase('tag')&&
                     !objTyp.getDescribe().getName().containsignorecase('share') && !objTyp.getDescribe().getName().containsignorecase('feed') && !objTyp.getDescribe().getName().containsignorecase('Event')){
                        sobjectname.add(new OptionWrapper(res.getLabel(),objTyp.getDescribe().getName()));
            }
        }
        return sobjectname;
    }
     @AuraEnabled(cacheable=true)
    public static List<FildWrapper> getAccounts(String objectName){
        List<FildWrapper> accList = new List<FildWrapper>();
        String str = 'select Id,name from '+ objectName;
        List<SObject> accoutList = Database.query(str);
        for(SObject c :accoutList){
            accList.add(new FildWrapper((String)c.get('Name'),(Id)c.get('Id')));
        }
        system.debug(accList);
        return accList;
    } 

    @AuraEnabled(cacheable=true)
    public static List<OptionWrapper> getObjecttFields(String objecttid){
        String parentObjName = '';
        parentObjName = getObjectNameFromId(objecttid);
        List<OptionWrapper> optionlist = new List<OptionWrapper>();
        SObjectType contactType = Schema.getGlobalDescribe().get(parentObjName);
        Map<String,Schema.SObjectField> mfields = contactType.getDescribe().fields.getMap();
        for(String s : mfields.keySet()){
            if(mfields.get(s).getDescribe().isUpdateable() && mfields.get(s).getDescribe().isCreateable()){
                optionlist.add(new OptionWrapper(String.valueOf(mfields.get(s)),String.valueOf(mfields.get(s))));
            }
        }
        return optionlist;
    }

     @AuraEnabled
    public static  List<ChildObjectWrapper> cloneAccont(String accountid){
        List<ChildObjectWrapper> childObjWrapperList = new List<ChildObjectWrapper>();
        String parentObjName = '';
        parentObjName = getObjectNameFromId(accountid);
        List<Schema.ChildRelationship> childObjList = getChildRelationshipsFromId(accountid);
        for(Schema.ChildRelationship child : childObjList){
            if(child.getChildSObject().getDescribe().isQueryable()){
                if(child.getField().getDescribe().isCreateable() && child.getField().getDescribe().isAccessible()){
                    if(child.getField().getDescribe().getName().containsignorecase(parentObjName)){
                        childObjWrapperList.add(new ChildObjectWrapper(child.getChildSObject().getDescribe().getName(),false,accountid,String.valueOf(child.getField())));
                    }
                }
            }
        }
        return childObjWrapperList;
    }

    public static String getObjectNameFromId(Id recordId){
        Schema.DescribeSObjectResult dr = getDescribeSObjectResultFromId(recordId);
        return dr.getName(); 
    }
     public static List<Schema.ChildRelationship> getChildRelationshipsFromId(Id recordId){
        Schema.DescribeSObjectResult dr = getDescribeSObjectResultFromId(recordId);
        return dr.getChildRelationships();
    }
     public static Schema.DescribeSObjectResult getDescribeSObjectResultFromId(Id recordId){
        Schema.SObjectType token = recordId.getSObjectType();
        return token.getDescribe();
    }

    @AuraEnabled
    public static Id cloneWithChildren(List<String> childList, String recId,  Map<String,String> arrayfiled){
       
        List<ChildObjectWrapper> slctdChildObjWrapperList = new List<ChildObjectWrapper>();
        List<String> word = recId.split('-');
        String parentId = word[0];
        List<ChildObjectWrapper> childObjWrapperListobj = cloneAccont(parentId);
        String parentObjName = '';
        parentObjName = getObjectNameFromId(parentId);
          for(ChildObjectWrapper chldObj : childObjWrapperListobj){
              for(String s : childList){
                    if(chldObj.objName == s){
                        slctdChildObjWrapperList.add(chldObj);
                     }
                }
            }
            List<Sobject> clonedParentObj = cloneObject(parentObjName,parentId,true,null,null);
            insert clonedParentObj;
            Id myId = clonedParentObj.get(0).Id;
            Schema.SObjectType sobjectType = myId.getSObjectType();
            String sobjectName = sobjectType.getDescribe().getName();
            List<SObject> record = Database.query('Select Id, Name From ' + sobjectName + ' Where Id = :myId');
            SObject record1 = myId.getSObjectType().newSObject(myId);
            for(String str : arrayfiled.keySet()){
                record1.put(str,arrayfiled.get(str));
              }
            update record1;
        
            List<sobject> childObjList = new List<sobject>();
            if(slctdChildObjWrapperList.size() > 0){
                for(ChildObjectWrapper obj : slctdChildObjWrapperList){
                    List<Sobject> clonedChildObj = cloneObject(obj.objName,obj.recordId,false,obj.relationshipName,clonedParentObj.get(0).Id);
                    if(clonedChildObj.size() > 0){
                        childObjList.addAll(clonedChildObj);
                    }
                }
            }
            Database.insert(childObjList,false);

        return clonedParentObj.get(0).Id;
    }

    public static List<Sobject> cloneObject(String objName, Id orgRecordId, Boolean isSelfId,String relationshipField, String parentRecordId){
        
        SObjectType objToken = Schema.getGlobalDescribe().get(objName);
        DescribeSObjectResult objDef = objToken.getDescribe();
        Map<String, SObjectField> fields = objDef.fields.getMap();
        List<String> fieldslist = new List<String>();
        for(String fieldName : fields.keySet()) {
            if(fields.containsKey(fieldName) && fields.get(fieldName).getDescribe().isCreateable()){
                fieldslist.add(fieldName);
            }
        }
        
        
        if(objName.equals('OpportunityLineItem')){
            Set<String> fieldsSet = new Set<String>(fieldslist);
            if(fieldsSet.contains('unitprice') && fieldsSet.contains('totalprice')){
                fieldsSet.remove('totalprice');
                fieldslist.clear();
                fieldslist.addAll(fieldsSet);
            }
        }
        
        String query;
        if(isSelfId){
            query   = 'SELECT ' + String.join(fieldslist, ',') + ' FROM '+ objName +' WHERE Id =\''+ orgRecordId +'\' LIMIT 1';
        }else{
            query   = 'SELECT ' + String.join(fieldslist, ',') + ' FROM '+ objName +' WHERE '+ relationshipField +' =\''+ orgRecordId +'\'';
        }
        List<SObject> sObjList = new List<SObject>();
        if(fieldslist.size() > 0){
            sObjList = Database.query(query); 
        }
        List<SObject> clonedObjList = new List<SObject>();
        SObject clonedSobj;
        for(Sobject obj : sObjList){
            clonedSobj  = obj.clone(false, true, false, false);
            if(!isSelfId && clonedSobj!=null){
                if(String.isNotBlank(relationshipField) && String.isNotBlank(parentRecordId)){
                    clonedSobj.put(relationshipField,parentRecordId);
                }
            }
            clonedObjList.add(clonedSobj);
        }
        return clonedObjList;
    }

    public class OptionWrapper {
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String value {get; set;}
    
        public OptionWrapper(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

     public class FildWrapper {
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public Id value {get; set;}
       
        public FildWrapper(String label, id value) {
            this.label = label;
            this.value = value;
        }
    } 

    public class ChildObjectWrapper{
        @AuraEnabled
        public String objName {get;set;}
        @AuraEnabled
        public boolean isSelected {get;set;}
        @AuraEnabled
        public String recordId {get;set;}
        @AuraEnabled
        public String relationshipName {get;set;}
        
        ChildObjectWrapper(String objName, Boolean isSelected,String recordId, String relationshipName){

            this.objName = objName;
            this.isSelected = isSelected;
            this.recordId = recordId;
            this.relationshipName = relationshipName;
        }
     }      
}
