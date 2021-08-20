public with sharing class Flags {
    public static List<Feature_Flag__mdt> flags {
        get {
            if (flags == null) {
                flags = [
                    SELECT
                        Id,
                        DeveloperName,
                        Label,
                        Category__c,
                        Code__c,
                        Description__c,
                        Enabled__c,
                        Object__c,
                        Settings__c
                    FROM Feature_Flag__mdt
                ];
            }
            return flags;
        }
        set;
    }

    public static Map<String, Feature_Flag__mdt> flagsByCode {
        get {
            if (flagsByCode == null) {
                flagsByCode = new Map<String, Feature_Flag__mdt>();
                for (Feature_Flag__mdt f : flags) {
                    flagsByCode.put(f.Code__c, f);
                }
            }
            return flagsByCode;
        }
        set;
    }

    public static User_Feature_Flag__c userFlag {
        get {
            if (userFlag == null) {
                // get the default userFlag setting.  will return the most specific available.  (user, then profile, then org)
                userFlag = User_Feature_Flag__c.getInstance();

                // if userFlag is null, that means there's nothing at any level.  exit now.
                if (userFlag == null)
                    return null;

                // if userFlag is inactive, and at the user level, try going up to the profile level
                // if not at the user level, it's already at the profile or above, so we don't need to query for profile
                if (
                    userFlag.Active__c != true &&
                    userFlag.SetupOwnerId == UserInfo.getUserId()
                ) {
                    userFlag = User_Feature_Flag__c.getInstance(
                        UserInfo.getProfileId()
                    );
                }

                // if userFlag is inactive and not already at the org level, try going up to the org level
                if (
                    (userFlag == null || userFlag.Active__c != true) &&
                    userFlag.SetupOwnerId != UserInfo.getOrganizationId()
                )
                    userFlag = User_Feature_Flag__c.getOrgDefaults();

                // if userFlag is still inactive, return null;
                if (userFlag == null || userFlag.Active__c != true)
                    userFlag = null;
            }
            return userFlag;
        }
        set;
    }

    public static Result check(String code) {
        if(String.isBlank(code)) {
            throw new Utils.AppException('Feature Flag Code must not be blank');
        }
        Result r = new Result();
        r.flagRecord = flagsByCode.get(code);
        r.userFlag = userFlag;

        if(r.flagRecord == null) {
            r.enabled = true;
            r.explanation = 'No Feature Flag found with code: ' + code;

            if(r.userFlag != null && flagIsInCodeString(code, r.userFlag.Feature_Opt_OUT__c)) {
                r.enabled = false;
                r.explanation = 'No Feature Flag found with code, but User Flag opted out by code';
            }
            return r;
        } 

        if(r.flagRecord.Enabled__c == true) {
            r.enabled = true;
            r.explanation = 'Feature Flag enabled; User flag did not override.';

            if(r.userFlag == null) {
                r.explanation = 'Feature Flag enabled; No user flag found.';
                return r;
            }

            if(flagIsInCategoryString(r.flagRecord.Category__c, r.flagRecord.Object__c, r.userFlag.Category_Opt_OUT__c)) {
                r.enabled = false;
                r.explanation = 'Feature Flag enabled, but User Flag opted out by Category';
            }

            if(!r.enabled && flagIsInCodeString(code, r.userFlag.Feature_Opt_IN__c)) {
                r.enabled = true;
                r.explanation = 'Feature Flag enabled; User Flag opted out by Category, but opted in by Code';
            }

            if(r.enabled && flagIsInCodeString(code, r.userFlag.Feature_Opt_OUT__c)) {
                r.enabled = false;
                r.explanation = 'Feature Flag enabled, but User Flag opted out by Code.';
            }
        } else {
            r.enabled = false;
            r.explanation = 'Feature Flag disabled; User flag did not override.';

            if(r.userFlag == null) {
                r.explanation = 'Feature Flag disabled; No user flag found.';
                return r;
            }

            if(flagIsInCategoryString(r.flagRecord.Category__c, r.flagRecord.Object__c, r.userFlag.Category_Opt_IN__c)) {
                r.enabled = true;
                r.explanation = 'Feature Flag disabled, but User Flag opted in by Category';
            }

            if(r.enabled && flagIsInCodeString(code, r.userFlag.Feature_Opt_OUT__c)) {
                r.enabled = false;
                r.explanation = 'Feature Flag disabled; User Flag opted in by Category, but opted out by Code';
            }

            if(!r.enabled && flagIsInCodeString(code, r.userFlag.Feature_Opt_IN__c)) {
                r.enabled = true;
                r.explanation = 'Feature Flag disabled, but User Flag opted in by Code.';
            }
        }
        return r;
    }

    public static Result check(String category, String obj) {
        Result r = new Result();
        r.userFlag = userFlag;
        r.enabled = true;
        r.explanation = 'User Flag did not opt out of this category/object.';

        if(r.userFlag == null) {
            r.explanation = 'No User Flag found.';
            return r;
        } 

        if(flagIsInCategoryString(category, obj, r.userFlag.Category_Opt_OUT__c)) {
            r.enabled = false;
            r.explanation = 'User Flag opted out of this category/object.';
        }

        return r;
    }

    public static Boolean flagIsInCodeString(String code, String codeString) {
        if(String.isBlank(code)) return false;
        if(String.isBlank(codeString)) return false;
        Set<String> codes = new Set<String>(Utils.splitCsv(codeString.toLowerCase()));
        return codes.contains(code.trim().toLowerCase());
    }

    public static Boolean flagIsInCategoryString(String cat, String obj, String catString) {
        if(String.isBlank(cat)) return false;
        if(String.isBlank(catString)) return false;

        String categoryKey = new Set<String>{'trigger', 't'}.contains(cat.toLowerCase().trim())
            ? 'T'
            : new Set<String>{'process builder', 'p'}.contains(cat.toLowerCase().trim())
                ? 'P'
                : new Set<String>{'flow', 'f'}.contains(cat.toLowerCase().trim())
                    ? 'F'
                    : null;
        if(categoryKey == null) return false;

        for(String o: Utils.splitCsv(catString)) {
            List<String> opt = o.split('\\.');

            // if there's only 1 piece, then we're NOT narrowing by obj name.
            // if it matches this category, then return true (no need to consider object name).
            if(opt.size() == 1 && opt[0].equalsIgnoreCase(categoryKey)) {
                return true;
            }

            // if the first piece doesn't match the category key OR if there's no object name, then continue.  
            // there's no chance of this matching.
            if(!opt[0].equalsIgnoreCase(categoryKey) || String.isBlank(obj)) continue;

            // if the first piece matches the category key AND the second piece matches the object, 
            // then return true
            if(opt[1].equalsIgnoreCase(obj)) return true;
        }

        // we've looped through all opts in the string, and found no match.  return false.
        return false;
    }

    public class Result {
        @AuraEnabled
        public Boolean enabled { public get; public set; }
        @AuraEnabled
        public Feature_Flag__mdt flagRecord { public get; public set; }
        @AuraEnabled
        public User_Feature_Flag__c userFlag { public get; public set; }
        @AuraEnabled
        public String explanation { public get; public set; }
    }
}
