@isTest
public with sharing class TestDataFactory {

    // filter the given map to only the subset of keys provided
    public static Map<String, Object> filterKeys(
        Map<String, Object> orig,
        Set<String> keys
    ) {
        Map<String, Object> result = new Map<String, Object>();
        for (String key : orig.keySet()) {
            if (keys.contains(key)) {
                result.put(key, orig.get(key));
            }
        }
        return result;
    }

    public static Map<String, Integer> counters;
    public static Integer getNext(String sObjectName) {
        if (counters == null)
            counters = new Map<String, Integer>();
        sObjectName = sObjectName.toLowerCase().trim();
        Integer i = counters.get(sObjectName);
        if (i == null)
            i = 0;
        counters.put(sObjectName, (++i));
        return i;
    }

    public static sObject assignFieldVals(
        sObject obj,
        Map<String, Object> fieldVals
    ) {
        if (fieldVals != null && !fieldVals.isEmpty()) {
            for (String key : fieldVals.keySet()) {
                if (key.equalsIgnoreCase('RecordType'))
                    continue;
                if (key.equalsIgnoreCase('RecordTypeName'))
                    continue;
                if (key.equalsIgnoreCase('RecordTypeDevName'))
                    continue;
                if (key.equalsIgnoreCase('ProfileName'))
                    continue;
                if (key.equalsIgnoreCase('Profile'))
                    continue;
                obj.put(key, fieldVals.get(key));
            }
        }
        return obj;
    }

    public static Boolean doDml(sObject obj, Boolean doDml) {
        if (doDml == false)
            return false;
        insert obj;
        return true;
    }

    public static Boolean doDml(List<sObject> objs, Boolean doDml) {
        if (doDml == false)
            return false;
        insert objs;
        return true;
    }

    public static sObject finishWithRt(
        sObject obj,
        Map<String, Object> fieldVals,
        Boolean doDml
    ) {
        return finishWithRt(obj, fieldVals, null, doDml);
    }
    public static sObject finishWithRt(
        sObject obj,
        Map<String, Object> fieldVals,
        String defaultRecordTypeName,
        Boolean doDml
    ) {
        obj = populateRecordTypeId(obj, fieldVals, defaultRecordTypeName);
        return finish(obj, fieldVals, doDml);
    }
    public static sObject finish(
        sObject obj,
        Map<String, Object> fieldVals,
        Boolean doDml
    ) {
        obj = assignFieldVals(obj, fieldVals);
        doDml(obj, doDml);
        return obj;
    }

    public static String getName(
        String sObjectName,
        Map<String, Object> fieldVals
    ) {
        return getName(sObjectName, fieldVals, 'Name');
    }
    public static String getName(
        String sObjectName,
        Map<String, Object> fieldVals,
        String nameField
    ) {
        if (fieldVals != null && fieldVals.containsKey(nameField)) {
            return (String) fieldVals.get(nameField);
        } else {
            Integer i = getNext(sObjectName);
            return 'Test ' +
                sObjectName.replaceAll('__c', '').replaceAll('_', ' ') +
                ' ' +
                i;
        }
    }

    public static sObject populateRecordTypeId(
        sObject obj,
        Map<String, Object> fieldVals
    ) {
        return populateRecordTypeId(obj, fieldVals, null);
    }
    public static sObject populateRecordTypeId(
        sObject obj,
        Map<String, Object> fieldVals,
        String defaultRecordTypeName
    ) {
        if (fieldVals == null)
            return obj;
        if (obj == null)
            return obj;

        String rtName = (String) fieldVals.get('RecordType');
        if (rtName == null)
            rtName = (String) fieldVals.get('RecordTypeName');
        if (rtName == null)
            rtName = (String) fieldVals.get('RecordTypeDevName');
        if (rtName == null)
            rtName = defaultRecordTypeName;
        if (rtName == null)
            return obj;

        Schema.DescribeSObjectResult objDesc = obj.getSObjectType()
            .getDescribe();
        Map<String, Schema.RecordTypeInfo> rtsByDevName = objDesc.getRecordTypeInfosByDeveloperName();
        Map<String, Schema.RecordTypeInfo> rtsByName = objDesc.getRecordTypeInfosByName();

        Schema.RecordTypeInfo rti = rtsByDevName.get(rtName);
        if (rti == null)
            rti = rtsByName.get(rtName);
        if (rti == null)
            return obj;

        obj.put('RecordTypeId', rti.getRecordTypeId());
        return obj;
    }

    public static Map<String, Id> profilesByName {
        get {
            if (profilesByName == null) {
                profilesByName = new Map<String, Id>();
                for (Profile p : [SELECT Id, Name FROM Profile]) {
                    profilesByName.put(p.Name, p.Id);
                }
            }
            return profilesByName;
        }
        private set;
    }

    public static User createUser(
        Map<String, Object> fieldVals,
        Boolean doDml
    ) {
        Integer i = getNext('User');
        String profileName = 'System Administrator';
        Id profileId;
        if (fieldVals != null) {
            if (fieldVals.containsKey('ProfileId')) {
                profileId = (Id) fieldVals.get('ProfileId');
            } else if (fieldVals.containsKey('ProfileName')) {
                profileName = (String) fieldVals.get('ProfileName');
            } else if (fieldVals.containsKey('Profile')) {
                profileName = (String) fieldVals.get('ProfileName');
            }
        }
        if (profileId == null) {
            profileId = profilesByName.get(profileName);
        }
        User u = new User(
            Alias = 'test' + i,
            Email = 'test.user.' + i + '@maildrop.cc',
            FirstName = 'Test' + i,
            LastName = 'User' + i,
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'test.user.' + i + '@maildrop.cc',
            ProfileId = profileId
        );
        return (User) finish(u, fieldVals, doDml);
    }

    public static Feature_Flag__mdt createFeatureFlag(
        Map<String, Object> fieldVals
    ) {
        Integer i = getNext('Feature_Flag__mdt');
        Feature_Flag__mdt ff = new Feature_Flag__mdt(
            Label = 'Feature Flag ' + i,
            DeveloperName = 'Feature_Flag_' + i,
            Code__c = 'FF'+i,
            Enabled__c = true
        );
        return (Feature_Flag__mdt) finish(ff, fieldVals, false);
    }

    public static User_Feature_Flag__c createUserFeatureFlag(
        Map<String, Object> fieldVals,
        Boolean doDml
    ) {
        User_Feature_Flag__c uff = new User_Feature_Flag__c(
            SetupOwnerId = UserInfo.getUserId()
        );
        return (User_Feature_Flag__c) finish(uff, fieldVals, doDml);
    }

    public class TestDataException extends Exception {
    }
}