global with sharing class InvFlags {
    @InvocableMethod(label='Feature Flag Check')
    global static List<FlagCheckResult> flagCheck(List<FlagCheckRequest> reqs) {
        List<FlagCheckResult> r = new List<FlagCheckResult>();
        for (FlagCheckRequest req : reqs) {
            if (
                String.isBlank(req.code) &&
                String.isBlank(req.category) &&
                String.isBlank(req.objectName)
            ) {
                throw new Utils.AppException(
                    'You must provide either a Feature Flag Code or a Feature Flag Category and optional Object'
                );
            }
            Flags.Result res;
            if (String.isNotBlank(req.code)) {
                res = Flags.check(req.code);
            } else {
                res = Flags.check(req.category, req.objectName);
            }
            System.debug(
                'Invocable Flag Check:\n' +
                JSON.serializePretty(
                    new Map<String, Object>{ 'request' => req, 'result' => res }
                )
            );
            FlagCheckResult result = new FlagCheckResult();
            result.enabled = res.enabled;
            result.explanation = res.explanation;
            r.add(result);
        }
        return r;
    }

    global class FlagCheckRequest {
        @InvocableVariable
        global String code;
        @InvocableVariable
        global String category;
        @InvocableVariable
        global String objectName;
        global FlagCheckRequest() {}
        global FlagCheckRequest(String code) {
            this.code = code;
        }
        global FlagCheckRequest(String category, String objectName) {
            this.category = category;
            this.objectName = objectName;
        }
        global FlagCheckRequest(String code, String category, String objectName) {
            this.code = code;
            this.category = category;
            this.objectName = objectName;
        }
    }

    global class FlagCheckResult {
        @InvocableVariable
        global Boolean enabled;
        @InvocableVariable
        global String explanation;
    }
}
