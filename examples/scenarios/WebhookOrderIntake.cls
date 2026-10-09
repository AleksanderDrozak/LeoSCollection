@SuppressWarnings('PMD.AvoidGlobalModifier')
@RestResource(urlMapping='/leoSFCollection/orders/*')
global with sharing class WebhookOrderIntake {

    /**
     * An inbound order arrives as one JSON body and has to leave as four things: an Account, its
     * Contacts, one follow-up Task per requested service, and a quoted total.
     *
     * This example is written to sit exactly on the boundary, so it uses the library in one place
     * and plain Apex in the others. The comments say which is which and why - a reader deciding
     * whether to adopt the library needs the boundary more than they need enthusiasm.
     */

    global class IntakeException extends Exception {}

    global class RequestedService {
        global String name;
        global Decimal quantity;
        global Decimal unitPrice;
        global String status;
    }

    global class Payload {
        global String externalId;
        global Account customer;
        global List<Contact> contacts;
        global List<RequestedService> services;
    }

    global class Result {
        global Account account;
        global List<Contact> contacts;
        global List<Task> followUps;
        global Decimal quotedTotal;
    }

    /**
     * The only fields a caller is allowed to influence; everything else it sends is dropped.
     *
     * This is where the library earns its place in this class. Projecting one object onto another is
     * a shape change, and expressing it as a map rather than as a run of assignments means the
     * allow-list is DATA - it can be built from configuration, or from a field set, without touching
     * this method. Six assignments could not be.
     */
    private static final Map<SObjectField, SObjectField> ALLOWED_CUSTOMER_FIELDS =
        new Map<SObjectField, SObjectField>{
            Account.Name => Account.Name,
            Account.Industry => Account.Industry,
            Account.BillingStreet => Account.BillingStreet,
            Account.BillingCity => Account.BillingCity,
            Account.BillingCountry => Account.BillingCountry
        };

    @HttpPost
    global static Result doPost() {
        return importOrder((Payload) JSON.deserialize(RestContext.request.requestBody.toString(), Payload.class));
    }

    global static Result importOrder(Payload payload) {

        if(payload.customer == null) {
            throw new IntakeException('Payload has no customer block');
        }

        /** an absent block is an empty block, not a reason to fail the whole request */
        payload.contacts = payload.contacts ?? new List<Contact>();
        payload.services = payload.services ?? new List<RequestedService>();

        Result result = new Result();

        result.account = (Account) Collection.of(new List<Account> { payload.customer })
            .transform(new ConvertFunction(Account.class, ALLOWED_CUSTOMER_FIELDS))
            .first();

        /** one field on one record is an assignment; the projection above was a shape change, this is not */
        result.account.Description = 'Webhook order ' + payload.externalId;

        insert result.account;

        /**
         * Plain Apex from here down. These steps are per-record rules over plain data - one guard,
         * one field, one accumulator - and Apex has no lambdas, so each one would need its own
         * function class to say what a single line already says.
         *
         * The email check below is the same condition DuplicateContactsInBatch writes as a library
         * filter, and the difference is not the condition: there it sits inside a chain that is already
         * being built, where a prebuilt filter costs nothing, while here it would mean splitting one
         * loop that also assigns AccountId and collects the survivors into two passes.
         */
        result.contacts = new List<Contact>();

        for(Contact incoming : payload.contacts) {
            if(incoming.Email != null && incoming.Email.contains('@')) {
                incoming.AccountId = result.account.Id;
                result.contacts.add(incoming);
            }
        }

        insert result.contacts;

        result.followUps = new List<Task>();
        result.quotedTotal = 0;

        for(RequestedService service : payload.services) {

            if(!wasRequested(service)) {
                continue;
            }

            result.followUps.add(new Task(
                WhatId = result.account.Id,
                Subject = 'Follow up: ' + service.name,
                ActivityDate = Date.today().addDays(3),
                Status = 'Not Started',
                Priority = 'Normal'
            ));

            /** an incomplete line is treated as worthless rather than blowing up the whole intake */
            Decimal quantity = service.quantity ?? 0;
            Decimal unitPrice = service.unitPrice ?? 0;

            result.quotedTotal += quantity * unitPrice;
        }

        insert result.followUps;

        return result;
    }

    /** the one predicate worth naming, because two places have to agree on what "requested" means */
    private static Boolean wasRequested(RequestedService service) {
        return service.status != null && service.status.equalsIgnoreCase('REQUESTED');
    }

    global static void demo() {

        String body = '{"externalId":"WEB-1042",' +
                      '"customer":{"Name":"Acme Sp. z o.o.","Industry":"Manufacturing","BillingCountry":"PL"},' +
                      '"contacts":[{"LastName":"Kowalski","Email":"j.kowalski@acme.example"},' +
                      '            {"LastName":"No Email","Email":null}],' +
                      '"services":[{"name":"Audit","quantity":2,"unitPrice":1500,"status":"REQUESTED"},' +
                      '            {"name":"Training","quantity":1,"unitPrice":900,"status":"CANCELLED"},' +
                      '            {"name":"Support","quantity":12,"unitPrice":250,"status":"REQUESTED"}]}';

        Savepoint beforeDemo = Database.setSavepoint();

        Result result = importOrder((Payload) JSON.deserialize(body, Payload.class));

        System.debug('Account: ' + result.account.Id);
        System.debug('Contacts kept: ' + result.contacts.size() + ' of 2 (one had no email)');
        System.debug('Follow-ups: ' + result.followUps.size() + ' of 3 (one was cancelled)');
        System.debug('Quoted total: ' + result.quotedTotal);

        Database.rollback(beforeDemo);
    }
}
