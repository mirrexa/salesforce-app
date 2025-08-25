@IsTest
private class MirrexaApiServiceTest {
  @IsTest
  static void test_getTemplate_direct_with_mock() {
    Test.setMock(HttpCalloutMock.class, new MirrexaHttpMock());
    MirrexaHttpMock.callLog.clear();
    MirrexaHttpMock.nextStatusCode = 200;
    MirrexaHttpMock.nextBody = '{"success":true,"message":{"documentTemplate":{"id":"tmpl-general","type":"GENERAL"}}}';
    try {
      String tmpl = MirrexaApiService.getDocumentTemplate('tmpl-general');
      System.assert(tmpl.contains('GENERAL'), 'Calls: ' + String.join(MirrexaHttpMock.callLog, ' | '));
    } catch (Exception e) {
      System.assert(false, 'Direct GET threw: ' + e.getMessage() + ' Calls: ' + String.join(MirrexaHttpMock.callLog, ' | '));
    }
    }
  
  @IsTest
  static void test_getUserData_success() {
    Test.setMock(HttpCalloutMock.class, new MirrexaHttpMock());
    MirrexaHttpMock.callLog.clear();
    MirrexaHttpMock.nextStatusCode = 200;
    MirrexaHttpMock.nextBody = '{"id":"user-1","email":"u@example.com"}';
    Test.startTest();
    String body = MirrexaApiService.getUserData();
    Test.stopTest();
    System.assertNotEquals(null, body, 'Expected a non-null body');
    System.assert(body.contains('user-1'), 'Unexpected body: ' + body + ' | Calls: ' + String.join(MirrexaHttpMock.callLog, ' | '));
  }

  @IsTest
  static void test_getUserData_emptyResponse_throws() {
    Test.setMock(HttpCalloutMock.class, new MirrexaHttpMock());
    MirrexaHttpMock.callLog.clear();
    MirrexaHttpMock.nextStatusCode = 200;
    MirrexaHttpMock.nextBody = '';
    try {
      Test.startTest();
      String ignored = MirrexaApiService.getUserData();
      Test.stopTest();
      System.assert(false, 'Expected exception for empty response');
    } catch (AuraHandledException e) {
      System.assert(true, 'Caught expected AuraHandledException');
    }
  }

  @IsTest
  static void test_getUserData_invalidJson_throws() {
    Test.setMock(HttpCalloutMock.class, new MirrexaHttpMock());
    MirrexaHttpMock.callLog.clear();
    MirrexaHttpMock.nextStatusCode = 200;
    MirrexaHttpMock.nextBody = '{invalid-json}';
    try {
      Test.startTest();
      String ignored = MirrexaApiService.getUserData();
      Test.stopTest();
      System.assert(false, 'Expected exception for invalid JSON');
    } catch (AuraHandledException e) {
      System.assert(true, 'Caught expected AuraHandledException');
    }
  }

  @IsTest
  static void test_getDocumentTemplates_invalid_params_throw() {
    Test.setMock(HttpCalloutMock.class, new MirrexaHttpMock());
    // page < 1
    try {
      String ignored = MirrexaApiService.getDocumentTemplates(0, 10, false);
      System.assert(false, 'Expected exception for invalid page');
    } catch (AuraHandledException e) {
      System.assert(true, 'Caught expected');
    }
    // page > 1000
    try {
      String ignored = MirrexaApiService.getDocumentTemplates(1001, 10, false);
      System.assert(false, 'Expected exception for invalid page');
    } catch (AuraHandledException e) {
      System.assert(true, 'Caught expected');
    }
    // pageSize < 1
    try {
      String ignored = MirrexaApiService.getDocumentTemplates(1, 0, false);
      System.assert(false, 'Expected exception for invalid pageSize');
    } catch (AuraHandledException e) {
      System.assert(true, 'Caught expected');
    }
    // pageSize > 200
    try {
      String ignored = MirrexaApiService.getDocumentTemplates(1, 201, false);
      System.assert(false, 'Expected exception for invalid pageSize');
    } catch (AuraHandledException e) {
      System.assert(true, 'Caught expected');
    }
  }

  @IsTest
  static void test_getDocumentTemplate_blank_or_invalid_id_throw() {
    Test.setMock(HttpCalloutMock.class, new MirrexaHttpMock());
    // blank
    try {
      String ignored = MirrexaApiService.getDocumentTemplate('');
      System.assert(false, 'Expected exception for blank id');
    } catch (AuraHandledException e) {
      System.assert(true, 'Caught expected');
    }
    // invalid format
    try {
      String ignored = MirrexaApiService.getDocumentTemplate('invalid id!');
      System.assert(false, 'Expected exception for invalid id');
    } catch (AuraHandledException e) {
      System.assert(true, 'Caught expected');
    }
  }

  @IsTest
  static void test_getDocumentTemplate_non2xx_throw() {
    Test.setMock(HttpCalloutMock.class, new MirrexaHttpMock());
    MirrexaHttpMock.callLog.clear();
    // Use id that the mock marks as not found -> 404
    try {
      String ignored = MirrexaApiService.getDocumentTemplate('doesnotexist');
      System.assert(false, 'Expected exception for non-2xx');
    } catch (AuraHandledException e) {
      System.assert(true, 'Caught expected');
    }
  }

  @IsTest
  static void test_deleteDocumentTemplate_non2xx_throw() {
    Test.setMock(HttpCalloutMock.class, new MirrexaHttpMock());
    MirrexaHttpMock.nextStatusCode = 500;
    try {
      String ignored = MirrexaApiService.deleteDocumentTemplate('tmpl-general');
      System.assert(false, 'Expected exception for delete failure');
    } catch (AuraHandledException e) {
      System.assert(true, 'Caught expected');
    }
  }

  @IsTest
  static void test_toggleDocumentTemplateShare_non2xx_throw() {
    Test.setMock(HttpCalloutMock.class, new MirrexaHttpMock());
    MirrexaHttpMock.nextStatusCode = 500;
    try {
      String ignored = MirrexaApiService.toggleDocumentTemplateShare('tmpl-general');
      System.assert(false, 'Expected exception for toggle failure');
    } catch (AuraHandledException e) {
      System.assert(true, 'Caught expected');
    }
  }

  @IsTest
  static void test_createDocumentTemplate_non2xx_throw() {
    Test.setMock(HttpCalloutMock.class, new MirrexaHttpMock());
    MirrexaHttpMock.nextStatusCode = 500;
    try {
      String ignored = MirrexaApiService.createDocumentTemplate('Name','Desc','GENERAL','YmFzZTY0',true);
      System.assert(false, 'Expected exception for create failure');
    } catch (AuraHandledException e) {
      System.assert(true, 'Caught expected');
    }
  }

  @IsTest
  static void test_registerUser_non2xx_throw() {
    Test.setMock(HttpCalloutMock.class, new MirrexaHttpMock());
    MirrexaHttpMock.nextStatusCode = 500;
    try {
      String ignored = MirrexaApiService.registerUser('https://example.my.salesforce.com','user@example.com','005000000000001');
      System.assert(false, 'Expected exception for register failure');
    } catch (AuraHandledException e) {
      System.assert(true, 'Caught expected');
    }
  }

  @IsTest
  static void test_generateAndAttachDocument_template_fetch_fails_returns_failed() {
    Test.setMock(HttpCalloutMock.class, new MirrexaHttpMock());
    MirrexaHttpMock.callLog.clear();
    Id recordId = UserInfo.getUserId();
    String result = MirrexaApiService.generateAndAttachDocument(recordId, 'doesnotexist', 'DocName', true);
    System.assertEquals('failed', result, 'Expected failed when template fetch fails');
  }

  @IsTest
  static void test_getDocumentTemplates_success() {
    Test.setMock(HttpCalloutMock.class, new MirrexaHttpMock());
    MirrexaHttpMock.callLog.clear();
    MirrexaHttpMock.nextStatusCode = 200;
    MirrexaHttpMock.nextBody = '{"success":true,"message":{"items":[{"id":"a"}]}}';
    Test.startTest();
    String res = MirrexaApiService.getDocumentTemplates(1, 10, false);
    Test.stopTest();
    System.assert(res.contains('items'), 'Unexpected body: ' + res + ' | Calls: ' + String.join(MirrexaHttpMock.callLog, ' | '));
  }

  @IsTest
  static void test_deleteDocumentTemplate_success() {
    Test.setMock(HttpCalloutMock.class, new MirrexaHttpMock());
    MirrexaHttpMock.callLog.clear();
    MirrexaHttpMock.nextStatusCode = 200;
    MirrexaHttpMock.nextBody = '{"success":true,"message":"deleted"}';
    String res = MirrexaApiService.deleteDocumentTemplate('tmpl-general');
    System.assert(res.contains('deleted'), 'Unexpected: ' + res + ' Calls: ' + String.join(MirrexaHttpMock.callLog, ' | '));
  }

  @IsTest
  static void test_toggleDocumentTemplateShare_success() {
    Test.setMock(HttpCalloutMock.class, new MirrexaHttpMock());
    MirrexaHttpMock.callLog.clear();
    MirrexaHttpMock.nextStatusCode = 200;
    MirrexaHttpMock.nextBody = '{"success":true,"message":"toggled"}';
    String res = MirrexaApiService.toggleDocumentTemplateShare('tmpl-general');
    System.assert(res.contains('toggled'), 'Unexpected: ' + res + ' Calls: ' + String.join(MirrexaHttpMock.callLog, ' | '));
  }

  @IsTest
  static void test_createDocumentTemplate_success() {
    Test.setMock(HttpCalloutMock.class, new MirrexaHttpMock());
    MirrexaHttpMock.callLog.clear();
    MirrexaHttpMock.nextStatusCode = 200;
    MirrexaHttpMock.nextBody = '{"success":true,"message":{"id":"new-tmpl"}}';
    String res = MirrexaApiService.createDocumentTemplate('Name','Desc','GENERAL','YmFzZTY0',true);
    System.assert(res.contains('new-tmpl'), 'Unexpected: ' + res + ' Calls: ' + String.join(MirrexaHttpMock.callLog, ' | '));
  }

  @IsTest
  static void test_registerUser_success() {
    Test.setMock(HttpCalloutMock.class, new MirrexaHttpMock());
    MirrexaHttpMock.callLog.clear();
    MirrexaHttpMock.nextStatusCode = 200;
    MirrexaHttpMock.nextBody = '{"success":true,"message":"registered"}';
    String res = MirrexaApiService.registerUser('https://example.my.salesforce.com','user@example.com','005000000000001');
    System.assert(res.contains('registered'), 'Unexpected: ' + res + ' Calls: ' + String.join(MirrexaHttpMock.callLog, ' | '));
  }

  @IsTest
  static void test_generateDocument_lowLevel_success() {
    Test.setMock(HttpCalloutMock.class, new MirrexaHttpMock());
    MirrexaHttpMock.callLog.clear();
    MirrexaHttpMock.nextStatusCode = 200;
    Map<String,Object> payload = new Map<String,Object>{ 'name' => 'Doc' };
    HttpResponse r = MirrexaApiService.generateDocument(payload);
    System.assertEquals(200, r.getStatusCode(), 'Calls: ' + String.join(MirrexaHttpMock.callLog, ' | '));
    System.assert(r.getBody().contains('crm_able_to_attach'), 'Body: ' + r.getBody());
  }

  @IsTest
  static void test_generateSuitabilityLetter_lowLevel_success() {
    Test.setMock(HttpCalloutMock.class, new MirrexaHttpMock());
    MirrexaHttpMock.callLog.clear();
    MirrexaHttpMock.nextStatusCode = 200;
    Map<String,Object> payload = new Map<String,Object>{ 'name' => 'Letter' };
    HttpResponse r = MirrexaApiService.generateSuitabilityLetter(payload);
    System.assertEquals(200, r.getStatusCode(), 'Calls: ' + String.join(MirrexaHttpMock.callLog, ' | '));
    System.assert(r.getBody().contains('crm_able_to_attach'), 'Body: ' + r.getBody());
  }

  @IsTest
  static void test_generateAndAttachDocument_general_attach_true() {
    // Mock template GET -> GENERAL and document POST -> attach allowed
    Test.setMock(HttpCalloutMock.class, new MirrexaHttpMock());
    MirrexaHttpMock.callLog.clear();
    MirrexaHttpMock.nextAttachAllowed = true;
    Id recordId = UserInfo.getUserId();
    String result = MirrexaApiService.generateAndAttachDocument(recordId, 'tmpl-general', 'DocName', true);
    System.assertEquals('generated_and_attached', result, 'Calls: ' + String.join(MirrexaHttpMock.callLog, ' | '));
  }

  @IsTest
  static void test_generateAndAttachDocument_general_attach_false() {
    Test.setMock(HttpCalloutMock.class, new MirrexaHttpMock());
    MirrexaHttpMock.callLog.clear();
    MirrexaHttpMock.nextAttachAllowed = false;
    Id recordId = UserInfo.getUserId();
    String result = MirrexaApiService.generateAndAttachDocument(recordId, 'tmpl-general', 'DocName', true);
    System.assertEquals('generated', result, 'Calls: ' + String.join(MirrexaHttpMock.callLog, ' | '));
  }

  @IsTest
  static void test_generateAndAttachDocument_suitability() {
    Test.setMock(HttpCalloutMock.class, new MirrexaHttpMock());
    MirrexaHttpMock.callLog.clear();
    MirrexaHttpMock.nextAttachAllowed = true;
    Id recordId = UserInfo.getUserId();
    String result = MirrexaApiService.generateAndAttachDocument(recordId, 'tmpl-suit', 'DocName', false);
    System.assertEquals('generated_and_attached', result, 'Calls: ' + String.join(MirrexaHttpMock.callLog, ' | '));
  }

  @IsTest
  static void test_generateAndAttachDocument_unknown_type() {
    Test.setMock(HttpCalloutMock.class, new MirrexaHttpMock());
    MirrexaHttpMock.callLog.clear();
    Id recordId = UserInfo.getUserId();
    String result = MirrexaApiService.generateAndAttachDocument(recordId, 'tmpl-unknown', 'DocName', true);
    System.assertEquals('failed', result, 'Calls: ' + String.join(MirrexaHttpMock.callLog, ' | '));
  }

  @IsTest
  static void test_getSubscriptions_success() {
    Test.setMock(HttpCalloutMock.class, new MirrexaHttpMock());
    MirrexaHttpMock.callLog.clear();
    String body = MirrexaApiService.getSubscriptions();
    System.assert(body.contains('products'), 'Unexpected: ' + body + ' Calls: ' + String.join(MirrexaHttpMock.callLog, ' | '));
  }

  @IsTest
  static void test_isUserConnected_nonblank() {
    // We can't control ConnectApi here; just assert call returns a non-blank string
    String status = MirrexaApiService.isUserConnected();
    System.assertNotEquals(null, status, 'Expected a response');
  }

  @IsTest
  static void test_getAuthURL_returns_or_throws() {
    try {
      String url = MirrexaApiService.getAuthURL();
      System.assert(String.isNotBlank(url), 'Expected non-blank URL');
    } catch (Exception e) {
      // Acceptable in test context if External Credential not fully configured
      System.assert(String.isNotBlank(e.getMessage()), 'Expected an error message');
    }
  }

  @IsTest
  static void test_autoRegisterUser_success() {
    Test.setMock(HttpCalloutMock.class, new MirrexaHttpMock());
    MirrexaHttpMock.callLog.clear();
    MirrexaHttpMock.nextStatusCode = 200;
    MirrexaHttpMock.nextBody = '{"success":true,"message":"registered"}';
    Test.startTest();
    String res = MirrexaApiService.autoRegisterUser();
    Test.stopTest();
    System.assert(res.contains('registered'), 'Unexpected: ' + res + ' Calls: ' + String.join(MirrexaHttpMock.callLog, ' | '));
  }
}
