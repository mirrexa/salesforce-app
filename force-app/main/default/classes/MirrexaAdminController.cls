/**
 * @description Controller class for Mirrexa admin dashboard functionality
 * Provides methods for user management and system configuration
 * @author Mirrexa Team
 * @date 2025-07-18
 */
public with sharing class MirrexaAdminController {
  private static final String PERMISSION_SET_NAME = 'Mirrexa_App_Access_2GP';
  private static final String NAMED_CREDENTIAL_NAME = 'Mirrexa_API';

  /**
   * @description Check if the Mirrexa_API Named Credential exists and return its URL
   * @return Map containing existence status and URL
   */
  @AuraEnabled(cacheable=true)
  public static Map<String, Object> checkNamedCredentialExists() {
    Map<String, Object> result = new Map<String, Object>();

    try {
      // Check FLS for NamedCredential object
      if (!Schema.sObjectType.NamedCredential.isAccessible()) {
        throw new AuraHandledException(
          'Insufficient permissions to access Named Credentials'
        );
      }

      // Check field-level security for required fields
      if (
        !Schema.sObjectType.NamedCredential.fields.Id.isAccessible() ||
        !Schema.sObjectType.NamedCredential.fields.DeveloperName.isAccessible()
      ) {
        throw new AuraHandledException(
          'Insufficient field permissions for Named Credentials'
        );
      }

      List<NamedCredential> credentials = [
        SELECT Id, DeveloperName
        FROM NamedCredential
        WHERE DeveloperName = :NAMED_CREDENTIAL_NAME
        LIMIT 1
      ];

      if (!credentials.isEmpty()) {
        result.put('exists', true);
        result.put(
          'url',
          '/lightning/setup/NamedCredential/' + credentials[0].Id + '/view'
        );
      } else {
        result.put('exists', false);
        result.put('url', '');
      }
    } catch (AuraHandledException e) {
      // Re-throw validation and security exceptions
      throw e;
    } catch (Exception e) {
      result.put('exists', false);
      result.put('url', '');
      result.put('error', e.getMessage());
    }
    return result;
  }

  /**
   * @description Get all users who have the Mirrexa_App_Access_2GP permission set assigned
   * @return List of users with permission set assignment details
   */
  @AuraEnabled(cacheable=true)
  @SuppressWarnings('PMD.AvoidDebugStatements')
  public static List<Map<String, Object>> getUsersWithMirrexaAccess() {
    List<Map<String, Object>> userList = new List<Map<String, Object>>();

    try {
      // Check FLS for PermissionSetAssignment object
      if (!Schema.sObjectType.PermissionSetAssignment.isAccessible()) {
        throw new AuraHandledException(
          'Insufficient permissions to access Permission Set Assignments'
        );
      }

      // Check field-level security for required fields
      if (
        !Schema.sObjectType.PermissionSetAssignment.fields.Id.isAccessible() ||
        !Schema.sObjectType.PermissionSetAssignment.fields.AssigneeId.isAccessible() ||
        !Schema.sObjectType.PermissionSetAssignment.fields.SystemModstamp.isAccessible()
      ) {
        throw new AuraHandledException(
          'Insufficient field permissions for Permission Set Assignments'
        );
      }

      // Check User object field access
      if (
        !Schema.sObjectType.User.fields.Name.isAccessible() ||
        !Schema.sObjectType.User.fields.Username.isAccessible() ||
        !Schema.sObjectType.User.fields.Email.isAccessible() ||
        !Schema.sObjectType.User.fields.IsActive.isAccessible()
      ) {
        throw new AuraHandledException(
          'Insufficient field permissions for User records'
        );
      }

      List<PermissionSetAssignment> assignments = [
        SELECT
          Id,
          AssigneeId,
          Assignee.Name,
          Assignee.Username,
          Assignee.Email,
          Assignee.IsActive,
          SystemModstamp,
          PermissionSet.Name
        FROM PermissionSetAssignment
        WHERE PermissionSet.Name = :PERMISSION_SET_NAME
        ORDER BY Assignee.Name
      ];

      for (PermissionSetAssignment assignment : assignments) {
        Map<String, Object> userInfo = new Map<String, Object>();
        userInfo.put('userId', assignment.AssigneeId);
        userInfo.put('name', assignment.Assignee.Name);
        userInfo.put('username', assignment.Assignee.Username);
        userInfo.put('email', assignment.Assignee.Email);
        userInfo.put('isActive', assignment.Assignee.IsActive);
        userInfo.put('assignedDate', assignment.SystemModstamp);
        userInfo.put('assignmentId', assignment.Id);
        userList.add(userInfo);
      }
    } catch (AuraHandledException e) {
      // Re-throw validation and security exceptions
      throw e;
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'Error getting users with Mirrexa access: ' + e.getMessage()
      );
    }

    return userList;
  }

  /**
   * @description Search for permission sets by name
   * @param searchTerm The search term to filter permission sets
   * @return List of permission sets matching the search term
   */
  @AuraEnabled(cacheable=true)
  @SuppressWarnings('PMD.AvoidDebugStatements')
  public static List<Map<String, Object>> searchPermissionSets(
    String searchTerm
  ) {
    List<Map<String, Object>> permSetList = new List<Map<String, Object>>();

    try {
      // Input validation
      if (String.isBlank(searchTerm)) {
        throw new AuraHandledException('Search term cannot be blank');
      }

      // Sanitize input to prevent SOQL injection
      String sanitizedSearchTerm = String.escapeSingleQuotes(searchTerm.trim());
      if (sanitizedSearchTerm.length() > 255) {
        throw new AuraHandledException('Search term too long');
      }

      // Check FLS for PermissionSet object
      if (!Schema.sObjectType.PermissionSet.isAccessible()) {
        throw new AuraHandledException(
          'Insufficient permissions to access Permission Sets'
        );
      }

      // Check field-level security for required fields
      if (
        !Schema.sObjectType.PermissionSet.fields.Id.isAccessible() ||
        !Schema.sObjectType.PermissionSet.fields.Name.isAccessible() ||
        !Schema.sObjectType.PermissionSet.fields.Label.isAccessible() ||
        !Schema.sObjectType.PermissionSet.fields.Description.isAccessible() ||
        !Schema.sObjectType.PermissionSet.fields.Type.isAccessible()
      ) {
        throw new AuraHandledException(
          'Insufficient field permissions for Permission Sets'
        );
      }

      String searchPattern = '%' + sanitizedSearchTerm + '%';
      List<PermissionSet> permissionSets = [
        SELECT Id, Name, Label, Description, Type
        FROM PermissionSet
        WHERE
          (Name LIKE :searchPattern
          OR Label LIKE :searchPattern)
          AND Type NOT IN ('Profile', 'Session')
          AND Name != :PERMISSION_SET_NAME
        ORDER BY Label
        LIMIT 200
      ];

      for (PermissionSet ps : permissionSets) {
        Map<String, Object> permSetInfo = new Map<String, Object>();
        permSetInfo.put('id', ps.Id);
        permSetInfo.put('name', ps.Name);
        permSetInfo.put('label', ps.Label);
        permSetInfo.put('description', ps.Description);
        permSetList.add(permSetInfo);
      }
    } catch (AuraHandledException e) {
      // Re-throw validation and security exceptions
      throw e;
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'Error searching permission sets: ' + e.getMessage()
      );
    }

    return permSetList;
  }

  /**
   * @description Get users assigned to a specific permission set
   * @param permissionSetId The ID of the permission set
   * @return List of users assigned to the permission set
   */
  @AuraEnabled(cacheable=true)
  @SuppressWarnings('PMD.AvoidDebugStatements')
  public static List<Map<String, Object>> getUsersInPermissionSet(
    String permissionSetId
  ) {
    List<Map<String, Object>> userList = new List<Map<String, Object>>();

    try {
      // Input validation
      if (String.isBlank(permissionSetId)) {
        throw new AuraHandledException('Permission Set ID cannot be blank');
      }

      // Validate ID format
      if (
        !Pattern.matches('[a-zA-Z0-9]{15}|[a-zA-Z0-9]{18}', permissionSetId)
      ) {
        throw new AuraHandledException('Invalid Permission Set ID format');
      }

      // Check FLS for PermissionSetAssignment object
      if (!Schema.sObjectType.PermissionSetAssignment.isAccessible()) {
        throw new AuraHandledException(
          'Insufficient permissions to access Permission Set Assignments'
        );
      }

      // Check field-level security
      if (
        !Schema.sObjectType.PermissionSetAssignment.fields.Id.isAccessible() ||
        !Schema.sObjectType.PermissionSetAssignment.fields.AssigneeId.isAccessible()
      ) {
        throw new AuraHandledException(
          'Insufficient field permissions for Permission Set Assignments'
        );
      }

      // Check User object field access
      if (
        !Schema.sObjectType.User.fields.Name.isAccessible() ||
        !Schema.sObjectType.User.fields.Username.isAccessible() ||
        !Schema.sObjectType.User.fields.Email.isAccessible() ||
        !Schema.sObjectType.User.fields.IsActive.isAccessible()
      ) {
        throw new AuraHandledException(
          'Insufficient field permissions for User records'
        );
      }

      List<PermissionSetAssignment> assignments = [
        SELECT
          Id,
          AssigneeId,
          Assignee.Name,
          Assignee.Username,
          Assignee.Email,
          Assignee.IsActive
        FROM PermissionSetAssignment
        WHERE PermissionSetId = :permissionSetId AND Assignee.IsActive = TRUE
        ORDER BY Assignee.Name
        LIMIT 1000
      ];

      for (PermissionSetAssignment assignment : assignments) {
        Map<String, Object> userInfo = new Map<String, Object>();
        userInfo.put('userId', assignment.AssigneeId);
        userInfo.put('name', assignment.Assignee.Name);
        userInfo.put('username', assignment.Assignee.Username);
        userInfo.put('email', assignment.Assignee.Email);
        userInfo.put('isActive', assignment.Assignee.IsActive);
        userList.add(userInfo);
      }
    } catch (AuraHandledException e) {
      // Re-throw validation and security exceptions
      throw e;
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'Error getting users in permission set: ' + e.getMessage()
      );
    }

    return userList;
  }

  /**
   * @description Assign Mirrexa_App_Access_2GP permission set to users from another permission set
   * @param sourcePermissionSetId The ID of the source permission set
   * @param userIds List of user IDs to assign the permission set to
   * @return Map containing success status and details
   */
  @AuraEnabled
  @SuppressWarnings('PMD.AvoidDebugStatements')
  public static Map<String, Object> assignMirrexaAccessToUsers(
    String sourcePermissionSetId,
    List<String> userIds
  ) {
    Map<String, Object> result = new Map<String, Object>();
    List<String> successfulAssignments = new List<String>();
    List<String> failedAssignments = new List<String>();

    try {
      // Input validation
      if (String.isBlank(sourcePermissionSetId)) {
        throw new AuraHandledException(
          'Source Permission Set ID cannot be blank'
        );
      }

      if (userIds == null || userIds.isEmpty()) {
        throw new AuraHandledException('User IDs list cannot be empty');
      }

      if (userIds.size() > 200) {
        throw new AuraHandledException(
          'Cannot process more than 200 users at once'
        );
      }

      // Validate user IDs format
      for (String userId : userIds) {
        if (!Pattern.matches('[a-zA-Z0-9]{15}|[a-zA-Z0-9]{18}', userId)) {
          throw new AuraHandledException('Invalid User ID format: ' + userId);
        }
      }

      // Check CRUD permissions for PermissionSetAssignment
      if (!Schema.sObjectType.PermissionSetAssignment.isCreateable()) {
        throw new AuraHandledException(
          'Insufficient permissions to create Permission Set Assignments'
        );
      }

      if (!Schema.sObjectType.PermissionSetAssignment.isAccessible()) {
        throw new AuraHandledException(
          'Insufficient permissions to access Permission Set Assignments'
        );
      }

      // Check PermissionSet access
      if (!Schema.sObjectType.PermissionSet.isAccessible()) {
        throw new AuraHandledException(
          'Insufficient permissions to access Permission Sets'
        );
      }

      // Get the Mirrexa permission set
      List<PermissionSet> mirrexaPermSet = [
        SELECT Id, Name
        FROM PermissionSet
        WHERE Name = :PERMISSION_SET_NAME
        LIMIT 1
      ];

      if (mirrexaPermSet.isEmpty()) {
        result.put('success', false);
        result.put('error', 'Mirrexa_App_Access_2GP permission set not found');
        return result;
      }

      String mirrexaPermSetId = mirrexaPermSet[0].Id;

      // Check which users already have the permission set
      Set<String> existingAssignments = new Set<String>();
      List<PermissionSetAssignment> existing = [
        SELECT AssigneeId
        FROM PermissionSetAssignment
        WHERE PermissionSetId = :mirrexaPermSetId AND AssigneeId IN :userIds
        LIMIT 1000
      ];

      for (PermissionSetAssignment psa : existing) {
        existingAssignments.add(psa.AssigneeId);
      }

      // Create new assignments for users who don't already have it
      List<PermissionSetAssignment> newAssignments = new List<PermissionSetAssignment>();
      for (String userId : userIds) {
        if (!existingAssignments.contains(userId)) {
          newAssignments.add(
            new PermissionSetAssignment(
              PermissionSetId = mirrexaPermSetId,
              AssigneeId = userId
            )
          );
        }
      }

      // Insert new assignments
      if (!newAssignments.isEmpty()) {
        // Final CRUD check before DML
        if (!Schema.sObjectType.PermissionSetAssignment.isCreateable()) {
          throw new AuraHandledException(
            'Insufficient permissions to create Permission Set Assignments'
          );
        }

        List<Database.SaveResult> saveResults = Database.insert(
          newAssignments,
          false
        );

        for (Integer i = 0; i < saveResults.size(); i++) {
          if (saveResults[i].isSuccess()) {
            successfulAssignments.add(newAssignments[i].AssigneeId);
          } else {
            failedAssignments.add(
              newAssignments[i].AssigneeId +
                ': ' +
                saveResults[i].getErrors()[0].getMessage()
            );
          }
        }
      }

      // Add existing assignments to successful list
      successfulAssignments.addAll(existingAssignments);

      result.put('success', true);
      result.put('successfulAssignments', successfulAssignments);
      result.put('failedAssignments', failedAssignments);
      result.put('totalProcessed', userIds.size());
      result.put('newAssignments', newAssignments.size());
      result.put('existingAssignments', existingAssignments.size());
    } catch (AuraHandledException e) {
      // Re-throw validation and security exceptions
      throw e;
    } catch (Exception e) {
      result.put('success', false);
      result.put('error', e.getMessage());
      System.debug(
        LoggingLevel.ERROR,
        'Error assigning Mirrexa access: ' + e.getMessage()
      );
    }

    return result;
  }

  /**
   * @description Remove Mirrexa_App_Access_2GP permission set from specific users
   * @param userIds List of user IDs to remove the permission set from
   * @return Map containing success status and details
   */
  @AuraEnabled
  @SuppressWarnings('PMD.AvoidDebugStatements')
  public static Map<String, Object> removeMirrexaAccessFromUsers(
    List<String> userIds
  ) {
    Map<String, Object> result = new Map<String, Object>();

    try {
      // Input validation
      if (userIds == null || userIds.isEmpty()) {
        throw new AuraHandledException('User IDs list cannot be empty');
      }

      if (userIds.size() > 200) {
        throw new AuraHandledException(
          'Cannot process more than 200 users at once'
        );
      }

      // Validate user IDs format
      for (String userId : userIds) {
        if (!Pattern.matches('[a-zA-Z0-9]{15}|[a-zA-Z0-9]{18}', userId)) {
          throw new AuraHandledException('Invalid User ID format: ' + userId);
        }
      }

      // Check CRUD permissions
      if (!Schema.sObjectType.PermissionSetAssignment.isAccessible()) {
        throw new AuraHandledException(
          'Insufficient permissions to access Permission Set Assignments'
        );
      }

      if (!Schema.sObjectType.PermissionSetAssignment.isDeletable()) {
        throw new AuraHandledException(
          'Insufficient permissions to delete Permission Set Assignments'
        );
      }

      List<PermissionSetAssignment> assignmentsToDelete = [
        SELECT Id
        FROM PermissionSetAssignment
        WHERE
          PermissionSet.Name = :PERMISSION_SET_NAME
          AND AssigneeId IN :userIds
        LIMIT 1000
      ];

      if (!assignmentsToDelete.isEmpty()) {
        delete assignmentsToDelete;
        result.put('success', true);
        result.put('removedCount', assignmentsToDelete.size());
      } else {
        result.put('success', true);
        result.put('removedCount', 0);
        result.put('message', 'No assignments found to remove');
      }
    } catch (AuraHandledException e) {
      // Re-throw validation and security exceptions
      throw e;
    } catch (Exception e) {
      result.put('success', false);
      result.put('error', e.getMessage());
      System.debug(
        LoggingLevel.ERROR,
        'Error removing Mirrexa access: ' + e.getMessage()
      );
    }

    return result;
  }
}