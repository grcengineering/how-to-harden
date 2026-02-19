// HTH NetSuite Control 3.2: RESTlet and SuiteScript Security
// Profile: L2 | NIST: CM-7
// https://howtoharden.com/guides/netsuite/#32-restlet-and-suitescript-security

// HTH Guide Excerpt: begin sdk-secure-restlet
// Secure RESTlet example
// @NApiVersion 2.x
// @NScriptType Restlet
// @NModuleScope SameAccount
define(['N/record', 'N/runtime'], function(record, runtime) {

    function doGet(requestParams) {
        // Validate user permissions
        var user = runtime.getCurrentUser();
        if (user.role !== AUTHORIZED_ROLE_ID) {
            throw new Error('Unauthorized');
        }

        // Validate input parameters
        if (!requestParams.id || isNaN(requestParams.id)) {
            throw new Error('Invalid parameters');
        }

        // Rate limit check (implement externally)

        // Return data with minimal fields
        return {
            id: requestParams.id,
            // Only return necessary fields
        };
    }

    return {
        get: doGet
    };
});
// HTH Guide Excerpt: end sdk-secure-restlet
