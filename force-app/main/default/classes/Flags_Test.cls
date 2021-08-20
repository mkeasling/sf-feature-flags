@IsTest
public with sharing class Flags_Test {

    static void fillFlags() {
        Flags.flags = new List<Feature_Flag__mdt>{
            TestDataFactory.createFeatureFlag(new Map<String, Object>{
                'Code__c' => 'TOBI',
                'Description__c' => 'Trigger Opportunity Before Insert',
                'Category__c' => 'Trigger',
                'Object__c' => 'Opportunity'
            }),
            TestDataFactory.createFeatureFlag(new Map<String, Object>{
                'Code__c' => 'PABU',
                'Description__c' => 'Process Builder Account Before Update',
                'Category__c' => 'Process Builder',
                'Object__c' => 'Account',
                'Enabled__c' => false
            }),
            TestDataFactory.createFeatureFlag(new Map<String, Object>{
                'Code__c' => 'FCBU',
                'Description__c' => 'Flow Contact Before Update',
                'Category__c' => 'Flow',
                'Object__c' => 'Contact'
            }),
            TestDataFactory.createFeatureFlag(new Map<String, Object>{
                'Code__c' => 'OJS',
                'Description__c' => 'Other JIRA Sync',
                'Category__c' => 'Other'
            })
        };
    }

    private static testMethod void testCheckWithCode() {
        fillFlags();

        Flags.Result r;
        try {
            r = Flags.check('');
            System.assert(false, 'Should have thrown an exception, but did not');
        } catch(Exception e) {
            System.assertEquals('Feature Flag Code must not be blank', e.getMessage());
        }

        r = Flags.check('BADCODE');
        System.assertEquals(true, r.enabled);
        System.assertEquals('No Feature Flag found with code: BADCODE', r.explanation);

        r = Flags.check('TOBI');
        System.assertEquals(true, r.enabled);
        System.assertEquals('Feature Flag enabled; No user flag found.', r.explanation);

        r = Flags.check('PABU');
        System.assertEquals(false, r.enabled);
        System.assertEquals('Feature Flag disabled; No user flag found.', r.explanation);

        System.assertEquals(null, Flags.userFlag);

        User_Feature_Flag__c uff = TestDataFactory.createUserFeatureFlag(new Map<String, Object>{
            'Category_Opt_OUT__c' => 'T.Account'
        }, true);

        r = Flags.check('TOBI');
        System.assertEquals(true, r.enabled);
        System.assertEquals('Feature Flag enabled; User flag did not override.', r.explanation);

        Flags.userFlag.Category_Opt_OUT__c = 'T';

        r = Flags.check('TOBI');
        System.assertEquals(false, r.enabled);
        System.assertEquals('Feature Flag enabled, but User Flag opted out by Category', r.explanation);

        Flags.userFlag.Category_Opt_OUT__c = null;
        Flags.userFlag.Feature_Opt_OUT__c = 'TOBI';

        r = Flags.check('TOBI');
        System.assertEquals(false, r.enabled);
        System.assertEquals('Feature Flag enabled, but User Flag opted out by Code.', r.explanation);

        Flags.userFlag.Category_Opt_OUT__c = 'T';
        Flags.userFlag.Feature_Opt_OUT__c = null;
        Flags.userFlag.Feature_Opt_IN__c = 'TOBI';

        r = Flags.check('TOBI');
        System.assertEquals(true, r.enabled);
        System.assertEquals('Feature Flag enabled; User Flag opted out by Category, but opted in by Code', r.explanation);

        r = Flags.check('PABU');
        System.assertEquals(false, r.enabled);
        System.assertEquals('Feature Flag disabled; User flag did not override.', r.explanation);

        Flags.userFlag.Category_Opt_IN__c = 'P';

        r = Flags.check('PABU');
        System.assertEquals(true, r.enabled);
        System.assertEquals('Feature Flag disabled, but User Flag opted in by Category', r.explanation);

        Flags.userFlag.Category_Opt_IN__c = null;
        Flags.userFlag.Feature_Opt_IN__c = 'PABU';

        r = Flags.check('PABU');
        System.assertEquals(true, r.enabled);
        System.assertEquals('Feature Flag disabled, but User Flag opted in by Code.', r.explanation);

        Flags.userFlag.Category_Opt_IN__c = 'P';
        Flags.userFlag.Feature_Opt_IN__c = null;
        Flags.userFlag.Feature_Opt_OUT__c = 'PABU';

        r = Flags.check('PABU');
        System.assertEquals(false, r.enabled);
        System.assertEquals('Feature Flag disabled; User Flag opted in by Category, but opted out by Code', r.explanation);

        r = Flags.check('OJS');
        System.assertEquals(true, r.enabled);

        Flags.userFlag.Feature_Opt_OUT__c = 'BADCODE';

        r = Flags.check('BADCODE');
        System.assertEquals(false, r.enabled);
        System.assertEquals('No Feature Flag found with code, but User Flag opted out by code', r.explanation);
    }

    private static testMethod void testCheckWithCategoryAndObject() {
        fillFlags();

        Flags.Result r;
        
        r= Flags.check('F', 'Contact');
        System.assertEquals(true, r.enabled);
        System.assertEquals(null, r.userFlag);
        System.assertEquals(null, r.flagRecord);
        System.assertEquals('No User Flag found.', r.explanation);

        User_Feature_Flag__c uff = TestDataFactory.createUserFeatureFlag(new Map<String, Object>{
            'Category_Opt_OUT__c' => 'F.Account'
        }, true);

        r = Flags.check('F', 'Contact');
        System.assertEquals(true, r.enabled);
        System.assertEquals(uff.Id, r.userFlag.Id);
        System.assertEquals(null, r.flagRecord);
        System.assertEquals('User Flag did not opt out of this category/object.', r.explanation);

        Flags.userFlag.Category_Opt_OUT__c = 'F';

        r = Flags.check('Flow', 'Contact');
        System.debug(r);
        System.assertEquals(false, r.enabled);
        System.assertEquals('User Flag opted out of this category/object.', r.explanation);
    }

    private static testMethod void testInvocable() {
        try {
            InvFlags.flagCheck(new List<InvFlags.FlagCheckRequest>{
                new InvFlags.FlagCheckRequest()
            });
            System.assert(false, 'Should have thrown an exception, but did not');
        } catch(Exception e) {
            System.assertEquals('You must provide either a Feature Flag Code or a Feature Flag Category and optional Object', e.getMessage());
        }
        
        fillFlags();
        Flags.userFlag = null;

        List<InvFlags.FlagCheckRequest> reqs = new List<InvFlags.FlagCheckRequest>{
            new InvFlags.FlagCheckRequest('PABU'),
            new InvFlags.FlagCheckRequest('T', 'Opportunity'),
            new InvFlags.FlagCheckRequest('FCBU', 'Flow', 'Contact')
        };

        List<InvFlags.FlagCheckResult> result = InvFlags.flagCheck(reqs);
        System.debug(JSon.serializePretty(result));

        System.assertEquals(3, result.size());
        System.assertEquals(false, result[0].enabled);
        System.assertEquals(true, result[1].enabled);
        System.assertEquals(true, result[2].enabled);
    }

}
