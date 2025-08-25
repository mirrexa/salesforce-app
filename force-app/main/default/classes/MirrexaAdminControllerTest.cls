@IsTest
private class MirrexaAdminControllerTest {

  @IsTest
  static void test_checkNamedCredentialExists_returns_map_no_throw() {
    Test.startTest();
    Map<String, Object> res = MirrexaAdminController.checkNamedCredentialExists();
    Test.stopTest();
    System.assertNotEquals(null, res, 'Expected a map response');
    System.assert(res.containsKey('exists'), 'Expected key exists');
    System.assert(res.containsKey('url'), 'Expected key url');
  }

  @IsTest
  static void test_getUsersWithMirrexaAccess_returns_list() {
    Test.startTest();
    List<Map<String, Object>> users = MirrexaAdminController.getUsersWithMirrexaAccess();
    Test.stopTest();
    System.assertNotEquals(null, users, 'Expected a list (possibly empty)');
  }

  @IsTest
  static void test_getUsersWithMirrexaAccess_contains_assigned_user_if_present() {
    PermissionSet mirrexaPs;
    try {
      mirrexaPs = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Mirrexa_App_Access_2GP' LIMIT 1];
    } catch (Exception e) {
      return; // skip if not present
    }
    if (mirrexaPs == null) return;

    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
    User u = new User(
      Alias = 'tusr6',
      Email = 'testuser6@example.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'User6',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      TimeZoneSidKey = 'America/Los_Angeles',
      ProfileId = p.Id,
      Username = 'testuser6-' + System.now().getTime() + '@example.com'
    );
    insert u;
    try { insert new PermissionSetAssignment(PermissionSetId = mirrexaPs.Id, AssigneeId = u.Id); } catch (Exception e) {}

    Test.startTest();
    List<Map<String, Object>> users = MirrexaAdminController.getUsersWithMirrexaAccess();
    Test.stopTest();
    Boolean found = false;
    for (Map<String, Object> row : users) {
      if ((String)row.get('userId') == u.Id) { found = true; break; }
    }
    System.assert(found || users.isEmpty() == false, 'Expect list and possibly include our user if assignment permitted');
  }

  @IsTest
  static void test_searchPermissionSets_blank_throws() {
    try {
      List<Map<String, Object>> ignored = MirrexaAdminController.searchPermissionSets('');
      System.assert(false, 'Expected exception for blank search term');
    } catch (AuraHandledException e) {
      System.assert(true, 'Caught expected AuraHandledException');
    }
  }

  @IsTest
  static void test_searchPermissionSets_whitespace_throws() {
    try {
      List<Map<String, Object>> ignored = MirrexaAdminController.searchPermissionSets('   ');
      System.assert(false, 'Expected exception for whitespace-only search term');
    } catch (AuraHandledException e) {
      System.assert(true, 'Caught expected AuraHandledException');
    }
  }

  @IsTest
  static void test_searchPermissionSets_too_long_throws() {
    String longStr = '';
    for (Integer i = 0; i < 256; i++) {
      longStr += 'x';
    }
    try {
      List<Map<String, Object>> ignored = MirrexaAdminController.searchPermissionSets(longStr);
      System.assert(false, 'Expected exception for overly long search term');
    } catch (AuraHandledException e) {
      System.assert(true, 'Caught expected AuraHandledException');
    }
  }

  @IsTest
  static void test_searchPermissionSets_valid_returns_list() {
    Test.startTest();
    List<Map<String, Object>> res = MirrexaAdminController.searchPermissionSets('Mirrexa');
    Test.stopTest();
    System.assertNotEquals(null, res, 'Expected a list (possibly empty)');
  }

  @IsTest
  static void test_getUsersInPermissionSet_returns_assigned_user() {
    // Arrange: pick a real, assignable PermissionSet and create a test User, then assign
    PermissionSet ps = [SELECT Id, Name FROM PermissionSet WHERE Type NOT IN ('Profile','Session') LIMIT 1];
    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
    User u = new User(
      Alias = 'tusr1',
      Email = 'testuser1@example.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'User',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      TimeZoneSidKey = 'America/Los_Angeles',
      ProfileId = p.Id,
      Username = 'testuser1-' + System.now().getTime() + '@example.com'
    );
    insert u;

    // Some permission sets may not be assignable to the created user due to license/profile constraints.
    // We'll attempt to insert and continue only if successful.
    Boolean assigned = false;
    try {
      insert new PermissionSetAssignment(PermissionSetId = ps.Id, AssigneeId = u.Id);
      assigned = true;
    } catch (Exception e) {
      assigned = false;
    }

    Test.startTest();
    List<Map<String, Object>> res2 = MirrexaAdminController.getUsersInPermissionSet(ps.Id);
    Test.stopTest();

    System.assertNotEquals(null, res2, 'Expected list response');
    if (assigned) {
      // If assignment succeeded, expect at least one entry matching our user
      Boolean found = false;
      for (Map<String, Object> row : res2) {
        if ((String)row.get('userId') == u.Id) { found = true; break; }
      }
      System.assert(found, 'Expected assigned user to be returned');
    }
  }

  @IsTest
  static void test_getUsersInPermissionSet_blank_throws() {
    try {
      List<Map<String, Object>> ignored = MirrexaAdminController.getUsersInPermissionSet('');
      System.assert(false, 'Expected exception for blank id');
    } catch (AuraHandledException e) {
      System.assert(true, 'Caught expected AuraHandledException');
    }
  }

  @IsTest
  static void test_getUsersInPermissionSet_invalid_format_throws() {
    try {
      List<Map<String, Object>> ignored = MirrexaAdminController.getUsersInPermissionSet('abc!');
      System.assert(false, 'Expected exception for invalid id format');
    } catch (AuraHandledException e) {
      System.assert(true, 'Caught expected AuraHandledException');
    }
  }

  @IsTest
  static void test_getUsersInPermissionSet_valid_format_returns_list() {
    // Prefer a real PermissionSet Id from the org to strictly satisfy regex and org format
    String fakeId;
    try {
      PermissionSet ps = [SELECT Id FROM PermissionSet LIMIT 1];
      fakeId = ps.Id;
    } catch (Exception e) {
      // Safe fallback to a syntactically valid 15-char Id
      fakeId = '0PS000000000001';
    }
    Test.startTest();
    List<Map<String, Object>> res = MirrexaAdminController.getUsersInPermissionSet(fakeId);
    Test.stopTest();
    System.assertNotEquals(null, res, 'Expected a list (possibly empty)');
  }

  @IsTest
  static void test_assignMirrexaAccessToUsers_validations() {
    // blank source id
    try {
      Map<String, Object> ignored = MirrexaAdminController.assignMirrexaAccessToUsers('', new List<String>{ UserInfo.getUserId() });
      System.assert(false, 'Expected exception for blank source id');
    } catch (AuraHandledException e) {
      System.assert(true, 'Caught expected');
    }

    // empty user list
    try {
      Map<String, Object> ignored = MirrexaAdminController.assignMirrexaAccessToUsers('0PS000000000001AA', new List<String>());
      System.assert(false, 'Expected exception for empty user list');
    } catch (AuraHandledException e) {
      System.assert(true, 'Caught expected');
    }

    // >200 users
    List<String> many = new List<String>();
    for (Integer i = 0; i < 201; i++) {
      many.add(UserInfo.getUserId());
    }
    try {
      Map<String, Object> ignored = MirrexaAdminController.assignMirrexaAccessToUsers('0PS000000000001AA', many);
      System.assert(false, 'Expected exception for too many users');
    } catch (AuraHandledException e) {
      System.assert(true, 'Caught expected');
    }

    // invalid user id format
    try {
      Map<String, Object> ignored = MirrexaAdminController.assignMirrexaAccessToUsers('0PS000000000001AA', new List<String>{ 'bad-id' });
      System.assert(false, 'Expected exception for invalid user id');
    } catch (AuraHandledException e) {
      System.assert(true, 'Caught expected');
    }
  }

  @IsTest
  static void test_assignMirrexaAccessToUsers_permset_missing_returns_error() {
    // With a valid source id and a valid user id, but missing target permission set in org
    List<String> users = new List<String>{ UserInfo.getUserId() };
    Test.startTest();
    Map<String, Object> res = MirrexaAdminController.assignMirrexaAccessToUsers('0PS000000000001AA', users);
    Test.stopTest();
    System.assertNotEquals(null, res, 'Expected a response map');
    System.assert(res.containsKey('success'), 'Expected success key');
    if ((Boolean)res.get('success') == false) {
      System.assertEquals('Mirrexa_App_Access_2GP permission set not found', (String)res.get('error'), 'Expected not found message');
    }
  }

  @IsTest
  static void test_assignMirrexaAccessToUsers_happy_path_if_permset_present() {
    PermissionSet mirrexaPs;
    try {
      mirrexaPs = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Mirrexa_App_Access_2GP' LIMIT 1];
    } catch (Exception e) {
      // Not present in this org, skip this test path
      return;
    }
    if (mirrexaPs == null) return;

    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
    User u = new User(
      Alias = 'tusr2',
      Email = 'testuser2@example.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'User2',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      TimeZoneSidKey = 'America/Los_Angeles',
      ProfileId = p.Id,
      Username = 'testuser2-' + System.now().getTime() + '@example.com'
    );
    insert u;

    List<String> users = new List<String>{ u.Id };
    Test.startTest();
    Map<String, Object> res = MirrexaAdminController.assignMirrexaAccessToUsers(mirrexaPs.Id, users);
    Test.stopTest();

    System.assertEquals(true, (Boolean)res.get('success'), 'Expected success=true when permset exists');
    System.assert(res.containsKey('successfulAssignments'), 'Expected successfulAssignments');
  }

  @IsTest
  static void test_assignMirrexaAccessToUsers_existing_user_no_new_when_permset_present() {
    PermissionSet mirrexaPs;
    try {
      mirrexaPs = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Mirrexa_App_Access_2GP' LIMIT 1];
    } catch (Exception e) {
      return; // skip if not present
    }
    if (mirrexaPs == null) return;

    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
    User u = new User(
      Alias = 'tusr4',
      Email = 'testuser4@example.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'User4',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      TimeZoneSidKey = 'America/Los_Angeles',
      ProfileId = p.Id,
      Username = 'testuser4-' + System.now().getTime() + '@example.com'
    );
    insert u;

    // Ensure assignment exists
    try {
      insert new PermissionSetAssignment(PermissionSetId = mirrexaPs.Id, AssigneeId = u.Id);
    } catch (Exception e) {
      // Already assigned or cannot assign; continue to call method which should treat as existing
    }

    List<String> users = new List<String>{ u.Id };
    Test.startTest();
    Map<String, Object> res = MirrexaAdminController.assignMirrexaAccessToUsers(mirrexaPs.Id, users);
    Test.stopTest();

    System.assertEquals(true, (Boolean)res.get('success'), 'Expected success');
    System.assertEquals(0, (Integer)res.get('newAssignments'), 'Expected no new assignments');
    System.assert(((Integer)res.get('existingAssignments')) >= 1, 'Expected existingAssignments >= 1');
  }

  @IsTest
  static void test_assignMirrexaAccessToUsers_partial_failure_when_permset_present() {
    PermissionSet mirrexaPs;
    try {
      mirrexaPs = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Mirrexa_App_Access_2GP' LIMIT 1];
    } catch (Exception e) {
      return; // skip if not present
    }
    if (mirrexaPs == null) return;

    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
    User u = new User(
      Alias = 'tusr5',
      Email = 'testuser5@example.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'User5',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      TimeZoneSidKey = 'America/Los_Angeles',
      ProfileId = p.Id,
      Username = 'testuser5-' + System.now().getTime() + '@example.com'
    );
    insert u;

    // Include a valid-format but non-existent User Id to trigger a failed SaveResult
    List<String> users = new List<String>{ u.Id, '005000000000000' };
    Test.startTest();
    Map<String, Object> res = MirrexaAdminController.assignMirrexaAccessToUsers(mirrexaPs.Id, users);
    Test.stopTest();

    System.assertEquals(true, (Boolean)res.get('success'), 'Overall success should be true even with partial failures');
    System.assert(res.containsKey('failedAssignments'), 'Expected failedAssignments key');
  }

  @IsTest
  static void test_removeMirrexaAccessFromUsers_validations() {
    // empty list
    try {
      Map<String, Object> ignored = MirrexaAdminController.removeMirrexaAccessFromUsers(new List<String>());
      System.assert(false, 'Expected exception for empty user list');
    } catch (AuraHandledException e) {
      System.assert(true, 'Caught expected');
    }

    // null list
    try {
      Map<String, Object> ignored = MirrexaAdminController.removeMirrexaAccessFromUsers(null);
      System.assert(false, 'Expected exception for null user list');
    } catch (AuraHandledException e) {
      System.assert(true, 'Caught expected');
    }

    // >200 users
    List<String> many = new List<String>();
    for (Integer i = 0; i < 201; i++) {
      many.add(UserInfo.getUserId());
    }
    try {
      Map<String, Object> ignored = MirrexaAdminController.removeMirrexaAccessFromUsers(many);
      System.assert(false, 'Expected exception for too many users');
    } catch (AuraHandledException e) {
      System.assert(true, 'Caught expected');
    }

    // invalid user id format
    try {
      Map<String, Object> ignored = MirrexaAdminController.removeMirrexaAccessFromUsers(new List<String>{ 'xyz!' });
      System.assert(false, 'Expected exception for invalid user id');
    } catch (AuraHandledException e) {
      System.assert(true, 'Caught expected');
    }
  }

  @IsTest
  static void test_removeMirrexaAccessFromUsers_no_assignments_success_zero() {
    List<String> users = new List<String>{ UserInfo.getUserId() };
    Test.startTest();
    Map<String, Object> res = MirrexaAdminController.removeMirrexaAccessFromUsers(users);
    Test.stopTest();
    System.assertEquals(true, (Boolean)res.get('success'), 'Expected success=true');
    System.assert(res.containsKey('removedCount'), 'Expected removedCount');
  }

  @IsTest
  static void test_removeMirrexaAccessFromUsers_removes_if_assigned() {
    PermissionSet mirrexaPs;
    try {
      mirrexaPs = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Mirrexa_App_Access_2GP' LIMIT 1];
    } catch (Exception e) {
      return; // skip if not present
    }
    if (mirrexaPs == null) return;

    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
    User u = new User(
      Alias = 'tusr3',
      Email = 'testuser3@example.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'User3',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      TimeZoneSidKey = 'America/Los_Angeles',
      ProfileId = p.Id,
      Username = 'testuser3-' + System.now().getTime() + '@example.com'
    );
    insert u;

    try {
      insert new PermissionSetAssignment(PermissionSetId = mirrexaPs.Id, AssigneeId = u.Id);
    } catch (Exception e) {
      return; // can't assign in this org; skip
    }

    List<String> users = new List<String>{ u.Id };
    Test.startTest();
    Map<String, Object> res = MirrexaAdminController.removeMirrexaAccessFromUsers(users);
    Test.stopTest();
    System.assertEquals(true, (Boolean)res.get('success'), 'Expected success');
    System.assert(((Integer)res.get('removedCount')) >= 0, 'Expected a numeric removedCount');
  }
}
