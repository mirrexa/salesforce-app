/**
 * @description Service class for handling API communication with the Mirrexa platform.
 *              Provides methods for user authentication, document template management,
 *              document generation, and subscription management.
 * @author Mirrexa Development Team
 * @since API Version 64.0
 */
public with sharing class MirrexaApiService {
  // Namespace for 2GP packaging. Used to fully-qualify metadata names when required by ConnectApi.
  private static final String PACKAGE_NAMESPACE = 'mirrexa';

  /**
   * Qualify a metadata API name with the package namespace, unless already qualified.
   */
  private static String namespaced(String apiName) {
    if (String.isBlank(apiName)) return apiName;
    if (apiName.contains('__')) return apiName;
    return String.isBlank(PACKAGE_NAMESPACE) ? apiName : PACKAGE_NAMESPACE + '__' + apiName;
  }

  /**
   * Resolve the Named Credential developer name to use for callout endpoints.
   * Tries namespaced first, then plain. Returns the developer name string to
   * be used in 'callout:<developerName>' endpoints.
   */
  private static String resolveNamedCredentialDevName(String baseDevName) {
    try {
      // Will throw if namespaced NC doesn't exist
      ConnectApi.NamedCredential nc = ConnectApi.NamedCredentials.getNamedCredential(namespaced(baseDevName));
      if (nc != null) return nc.developerName; // already namespaced value
    } catch (Exception ignore) {
      // fall through to plain
    }
    // Plain (non-namespaced) fallback
    return baseDevName;
  }

  /**
   * Try to get a Credential by external credential name and principal, attempting namespaced first then plain.
   */
  private static ConnectApi.Credential getCredentialWithFallback(
    String externalCredentialBase,
    String principalName,
    ConnectApi.CredentialPrincipalType principalType
  ) {
    try {
      return ConnectApi.NamedCredentials.getCredential(
        namespaced(externalCredentialBase),
        principalName,
        principalType
      );
    } catch (Exception e1) {
      return ConnectApi.NamedCredentials.getCredential(
        externalCredentialBase,
        principalName,
        principalType
      );
    }
  }

  /**
   * Try to get an OAuth authentication URL, attempting namespaced external credential first then plain.
   */
  private static ConnectApi.OAuthCredentialAuthUrl getOAuthAuthUrlWithFallback(
    String externalCredentialBase,
    String principalName,
    ConnectApi.CredentialPrincipalType principalType
  ) {
    ConnectApi.OAuthCredentialAuthUrlInput input = new ConnectApi.OAuthCredentialAuthUrlInput();
    input.externalCredential = namespaced(externalCredentialBase);
    input.principalType = principalType;
    input.principalName = principalName;
    try {
      return ConnectApi.NamedCredentials.getOAuthCredentialAuthUrl(input);
    } catch (Exception e1) {
      ConnectApi.OAuthCredentialAuthUrlInput inputPlain = new ConnectApi.OAuthCredentialAuthUrlInput();
      inputPlain.externalCredential = externalCredentialBase;
      inputPlain.principalType = principalType;
      inputPlain.principalName = principalName;
      return ConnectApi.NamedCredentials.getOAuthCredentialAuthUrl(inputPlain);
    }
  }
  /**
   * @description Checks if the current user has a valid OAuth connection to the Mirrexa platform.
   * @return String indicating connection status: 'Connected', 'Not Connected', or error message
   * @example
   * String status = MirrexaApiService.isUserConnected();
   * if (status == 'Connected') {
   *     // User is authenticated
   * }
   */
  @AuraEnabled
  @SuppressWarnings('PMD.AvoidDebugStatements')
  public static String isUserConnected() {
    try {
      String externalCredentialBase = 'MirrexaOAuth';
      String principalName = 'Standard User Access';
      ConnectApi.CredentialPrincipalType principalType = ConnectApi.CredentialPrincipalType.PerUserPrincipal;
      ConnectApi.Credential actualCredential = getCredentialWithFallback(
        externalCredentialBase,
        principalName,
        principalType
      );

      if (
        actualCredential.authenticationStatus ==
        ConnectApi.CredentialAuthenticationStatus.CONFIGURED
      ) {
        return 'Connected';
      }
      return 'Not Connected';
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'Failed to check connection: ' + e.getMessage()
      );
      return e.getMessage();
    }
  }

  /**
   * @description Retrieves the OAuth authentication URL for connecting to the Mirrexa platform.
   * @return String containing the OAuth authentication URL
   * @throws AuraHandledException if unable to generate authentication URL
   * @example
   * String authUrl = MirrexaApiService.getAuthURL();
   * // Redirect user to authUrl for authentication
   */
  @AuraEnabled
  public static String getAuthURL() {
    String externalCredentialBase = 'MirrexaOAuth';
    String principalName = 'Standard User Access';
    ConnectApi.CredentialPrincipalType principalType = ConnectApi.CredentialPrincipalType.PerUserPrincipal;
    ConnectApi.OAuthCredentialAuthUrl output = getOAuthAuthUrlWithFallback(
      externalCredentialBase,
      principalName,
      principalType
    );
    return output.authenticationUrl;
  }

  /**
   * @description Fetches the current user's data from the Mirrexa API.
   * @return String containing JSON response with user data
   * @throws AuraHandledException if API call fails or returns invalid response
   * @example
   * String userData = MirrexaApiService.getUserData();
   * Map<String, Object> userInfo = (Map<String, Object>) JSON.deserializeUntyped(userData);
   */
  @AuraEnabled(cacheable=true)
  @SuppressWarnings('PMD.AvoidDebugStatements')
  public static String getUserData() {
    try {
      HttpRequest req = new HttpRequest();
      String ncDevName = resolveNamedCredentialDevName('Mirrexa_API');
      req.setEndpoint('callout:' + ncDevName + '/api/user');
      req.setMethod('GET');
      req.setHeader('Content-Type', 'application/json;charset=UTF-8');
      req.setTimeout(30000); // 30 second timeout

      Http http = new Http();
      HttpResponse res = http.send(req);

      if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
        String responseBody = res.getBody();
        // Validate response is not empty and is valid JSON
        if (String.isBlank(responseBody)) {
          throw new AuraHandledException('Empty response from Mirrexa API');
        }

        // Basic JSON validation to prevent malformed responses
        try {
          JSON.deserializeUntyped(responseBody);
          return responseBody;
        } catch (JSONException e) {
          throw new AuraHandledException(
            'Invalid response format from Mirrexa API'
          );
        }
      } else {
        throw new AuraHandledException(
          'Failed to fetch user data: ' +
            res.getStatus() +
            ' - HTTP ' +
            res.getStatusCode()
        );
      }
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'Failed to fetch user data: ' + e.getMessage()
      );
      throw new AuraHandledException(
        'Error fetching user data: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Retrieves document templates from the Mirrexa API with pagination support.
   * @param page Page number for pagination (1-1000), can be null
   * @param pageSize Number of templates per page (1-200), can be null
   * @param noLimit Whether to ignore pagination limits, can be null
   * @return String containing JSON response with document templates
   * @throws AuraHandledException if parameters are invalid or API call fails
   * @example
   * String templates = MirrexaApiService.getDocumentTemplates(1, 10, false);
   * // Process templates response
   */
  @AuraEnabled(cacheable=true)
  @SuppressWarnings('PMD.AvoidDebugStatements')
  public static String getDocumentTemplates(
    Integer page,
    Integer pageSize,
    Boolean noLimit
  ) {
    try {
      // Input validation
      if (page != null && (page < 0 || page > 1000)) {
        throw new AuraHandledException(
          'Page number must be between 1 and 1000'
        );
      }

      if (pageSize != null && (pageSize < 0 || pageSize > 200)) {
        throw new AuraHandledException('Page size must be between 1 and 200');
      }

      HttpRequest req = new HttpRequest();
      String ncDevName = resolveNamedCredentialDevName('Mirrexa_API');
      String endpoint = 'callout:' + ncDevName + '/api/document-templates';

      // Add pagination parameters if provided
      if (page != null || pageSize != null) {
        List<String> params = new List<String>();
        if (page != null) {
          params.add('page=' + String.valueOf(page));
        }
        if (pageSize != null) {
          params.add('limit=' + String.valueOf(pageSize));
        }
        if (noLimit != null) {
          params.add('noLimit=' + String.valueOf(noLimit));
        }
        endpoint += '?' + String.join(params, '&');
      }

      req.setEndpoint(endpoint);
      req.setMethod('GET');
      req.setHeader('Content-Type', 'application/json;charset=UTF-8');
      req.setTimeout(30000); // 30 second timeout

      Http http = new Http();
      HttpResponse res = http.send(req);

      String responseBody = res.getBody();
      System.debug(LoggingLevel.ERROR, responseBody);
      if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
        // Validate response
        if (String.isBlank(responseBody)) {
          throw new AuraHandledException('Empty response from Mirrexa API');
        }

        // Basic JSON validation
        try {
          JSON.deserializeUntyped(responseBody);
          return responseBody;
        } catch (JSONException e) {
          throw new AuraHandledException(
            'Invalid response format from Mirrexa API'
          );
        }
      } else {
        throw new AuraHandledException(
          'Failed to fetch document templates: ' +
            res.getStatus() +
            ' - HTTP ' +
            res.getStatusCode()
        );
      }
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'Failed to fetch document templates: ' + e.getMessage()
      );
      throw new AuraHandledException(
        'Error fetching document templates: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Retrieves a specific document template by its ID from the Mirrexa API.
   * @param templateId The unique identifier of the document template (alphanumeric, max 50 chars)
   * @return String containing JSON response with document template details
   * @throws AuraHandledException if templateId is invalid or API call fails
   * @example
   * String template = MirrexaApiService.getDocumentTemplate('template123');
   * Map<String, Object> templateData = (Map<String, Object>) JSON.deserializeUntyped(template);
   */
  @AuraEnabled(cacheable=true)
  @SuppressWarnings('PMD.AvoidDebugStatements')
  public static String getDocumentTemplate(String templateId) {
    try {
      // Input validation
      if (String.isBlank(templateId)) {
        throw new AuraHandledException('Template ID cannot be blank');
      }

      // Sanitize template ID to prevent injection
      String sanitizedTemplateId = String.escapeSingleQuotes(templateId.trim());
      if (!Pattern.matches('[a-zA-Z0-9_-]{1,50}', sanitizedTemplateId)) {
        throw new AuraHandledException('Invalid template ID format');
      }

      HttpRequest req = new HttpRequest();
      String ncDevName2 = resolveNamedCredentialDevName('Mirrexa_API');
      req.setEndpoint('callout:' + ncDevName2 + '/api/document-templates/' + sanitizedTemplateId);
      req.setMethod('GET');
      req.setHeader('Content-Type', 'application/json;charset=UTF-8');

      Http http = new Http();
      HttpResponse res = http.send(req);

      if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
        String responseBody = res.getBody();
        // Validate response
        if (String.isBlank(responseBody)) {
          throw new AuraHandledException('Empty response from Mirrexa API');
        }

        // Basic JSON validation
        try {
          JSON.deserializeUntyped(responseBody);
          return responseBody;
        } catch (JSONException e) {
          throw new AuraHandledException(
            'Invalid response format from Mirrexa API'
          );
        }
      } else {
        throw new AuraHandledException(
          'Failed to fetch document template: ' +
            res.getStatus() +
            ' - HTTP ' +
            res.getStatusCode()
        );
      }
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'Failed to fetch document template: ' + e.getMessage()
      );
      throw new AuraHandledException(
        'Error fetching document template: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Deletes a document template from the Mirrexa platform.
   * @param templateId The unique identifier of the document template to delete
   * @return String containing API response
   * @throws AuraHandledException if deletion fails
   * @example
   * String result = MirrexaApiService.deleteDocumentTemplate('template123');
   */
  @AuraEnabled(cacheable=false)
  @SuppressWarnings('PMD.AvoidDebugStatements')
  public static String deleteDocumentTemplate(String templateId) {
    try {
      HttpRequest req = new HttpRequest();
      String ncDevName3 = resolveNamedCredentialDevName('Mirrexa_API');
      req.setEndpoint('callout:' + ncDevName3 + '/api/document-templates/' + templateId);
      req.setMethod('DELETE');
      req.setHeader('Content-Type', 'application/json;charset=UTF-8');

      Http http = new Http();
      HttpResponse res = http.send(req);

      if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
        return res.getBody();
      } else {
        throw new AuraHandledException(
          'Failed to delete document template: ' +
            res.getStatus() +
            ' - ' +
            res.getBody()
        );
      }
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'Failed to delete document template: ' + e.getMessage()
      );
      throw new AuraHandledException(
        'Error deleting document template: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Toggles the sharing status of a document template.
   * @param templateId The unique identifier of the document template
   * @return String containing API response with updated sharing status
   * @throws AuraHandledException if toggle operation fails
   * @example
   * String result = MirrexaApiService.toggleDocumentTemplateShare('template123');
   */
  @AuraEnabled(cacheable=false)
  @SuppressWarnings('PMD.AvoidDebugStatements')
  public static String toggleDocumentTemplateShare(String templateId) {
    try {
      HttpRequest req = new HttpRequest();
      String ncDevName4 = resolveNamedCredentialDevName('Mirrexa_API');
      req.setEndpoint('callout:' + ncDevName4 + '/api/document-templates/' + templateId + '/toggle-share');
      req.setMethod('POST');
      req.setHeader('Content-Type', 'application/json;charset=UTF-8');

      Http http = new Http();
      HttpResponse res = http.send(req);

      if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
        return res.getBody();
      } else {
        throw new AuraHandledException(
          'Failed to toggle document template share: ' +
            res.getStatus() +
            ' - ' +
            res.getBody()
        );
      }
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'Failed to toggle document template share: ' + e.getMessage()
      );
      throw new AuraHandledException(
        'Error toggling document template share: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Creates a new document template in the Mirrexa platform.
   * @param name The name of the document template
   * @param description Description of the document template
   * @param type The type of document template (e.g., 'GENERAL', 'SUITABILITY_LETTER')
   * @param base64FileData Base64 encoded file data for the template
   * @param availableToOrganisation Whether the template should be available to the entire organization
   * @return String containing API response with created template details
   * @throws AuraHandledException if template creation fails
   * @example
   * String result = MirrexaApiService.createDocumentTemplate(
   *     'My Template', 'Template description', 'GENERAL', base64Data, true
   * );
   */
  @AuraEnabled(cacheable=false)
  @SuppressWarnings('PMD.AvoidDebugStatements')
  public static String createDocumentTemplate(
    String name,
    String description,
    String type,
    String base64FileData,
    Boolean availableToOrganisation
  ) {
    try {
      // Prepare the request payload
      Map<String, Object> payload = new Map<String, Object>{
        'name' => name,
        'description' => description,
        'type' => type,
        'base64_file_data' => base64FileData,
        'available_to_organisation' => availableToOrganisation
      };

      HttpRequest req = new HttpRequest();
      String ncDevName5 = resolveNamedCredentialDevName('Mirrexa_API');
      req.setEndpoint('callout:' + ncDevName5 + '/api/document-templates');
      req.setMethod('POST');
      req.setHeader('Content-Type', 'application/json;charset=UTF-8');
      req.setBody(JSON.serialize(payload));

      Http http = new Http();
      HttpResponse res = http.send(req);

      if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
        return res.getBody();
      } else {
        throw new AuraHandledException(
          'Failed to create document template: ' +
            res.getStatus() +
            ' - ' +
            res.getBody()
        );
      }
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'Failed to create document template: ' + e.getMessage()
      );
      throw new AuraHandledException(
        'Error creating document template: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Registers a Salesforce user with the Mirrexa platform.
   * @param instanceUrl The Salesforce instance URL
   * @param userName The Salesforce username
   * @param userId The Salesforce user ID
   * @return String containing registration response
   * @throws AuraHandledException if user registration fails
   * @example
   * String result = MirrexaApiService.registerUser(
   *     'https://myorg.salesforce.com', 'user@example.com', '005000000000000'
   * );
   */
  @AuraEnabled(cacheable=false)
  @SuppressWarnings('PMD.AvoidDebugStatements')
  public static String registerUser(
    String instanceUrl,
    String userName,
    String userId
  ) {
    try {
      // Prepare the request payload
      Map<String, Object> payload = new Map<String, Object>{
        'instanceUrl' => instanceUrl,
        'userName' => userName,
        'userId' => userId
      };

      HttpRequest req = new HttpRequest();
      String ncDevName6 = resolveNamedCredentialDevName('Mirrexa_API');
      req.setEndpoint('callout:' + ncDevName6 + '/api/salesforce/register-user');
      req.setMethod('POST');
      req.setHeader('Content-Type', 'application/json;charset=UTF-8');
      req.setBody(JSON.serialize(payload));

      Http http = new Http();
      HttpResponse res = http.send(req);

      if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
        return res.getBody();
      } else {
        throw new AuraHandledException(
          'Failed to create document template: ' +
            res.getStatus() +
            ' - ' +
            res.getBody()
        );
      }
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'Failed to create document template: ' + e.getMessage()
      );
      throw new AuraHandledException(
        'Error creating document template: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Generates a document by sending a comprehensive payload to the Mirrexa API.
   * @param payloadMap The comprehensive data payload containing document generation parameters
   * @return HttpResponse from the API call containing the generated document response
   * @throws Exception if document generation fails
   * @example
   * Map<String, Object> payload = new Map<String, Object>{
   *     'name' => 'My Document',
   *     'document_template_id' => 'template123',
   *     'salesforce_record_id' => recordId
   * };
   * HttpResponse response = MirrexaApiService.generateDocument(payload);
   */
  @SuppressWarnings('PMD.AvoidDebugStatements')
  public static HttpResponse generateDocument(Map<String, Object> payloadMap) {
    try {
      String jsonPayload = JSON.serializePretty(payloadMap);

      // Make the API call
      HttpRequest req = new HttpRequest();
      String ncDevName7 = resolveNamedCredentialDevName('Mirrexa_API');
      req.setEndpoint('callout:' + ncDevName7 + '/api/documents');
      req.setMethod('POST');
      req.setHeader('Content-Type', 'application/json;charset=UTF-8');
      req.setTimeout(60000);
      req.setBody(jsonPayload);

      Http http = new Http();
      HttpResponse res = http.send(req);

      return res;
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'Failed to generate document: ' + e.getMessage()
      );
      throw e;
    }
  }

  /**
   * @description Generates a suitability letter by sending a comprehensive payload to the Mirrexa API.
   * @param payloadMap The comprehensive data payload containing suitability letter generation parameters
   * @return HttpResponse from the API call containing the generated suitability letter response
   * @throws Exception if suitability letter generation fails
   * @example
   * Map<String, Object> payload = new Map<String, Object>{
   *     'name' => 'Suitability Letter',
   *     'document_template_id' => 'template123',
   *     'salesforce_record_id' => recordId
   * };
   * HttpResponse response = MirrexaApiService.generateSuitabilityLetter(payload);
   */
  @SuppressWarnings('PMD.AvoidDebugStatements')
  public static HttpResponse generateSuitabilityLetter(
    Map<String, Object> payloadMap
  ) {
    try {
      String jsonPayload = JSON.serializePretty(payloadMap);

      // Make the API call
      HttpRequest req = new HttpRequest();
      String ncDevName8 = resolveNamedCredentialDevName('Mirrexa_API');
      req.setEndpoint('callout:' + ncDevName8 + '/api/suitability-letters');
      req.setMethod('POST');
      req.setHeader('Content-Type', 'application/json;charset=UTF-8');
      req.setTimeout(60000);
      req.setBody(jsonPayload);

      Http http = new Http();
      HttpResponse res = http.send(req);

      return res;
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'Failed to generate document: ' + e.getMessage()
      );
      throw e;
    }
  }

  /**
   * @description Generates and attaches a document to a Salesforce record using a Mirrexa template.
   *              Automatically determines the template type and calls the appropriate generation method.
   * @param recordId The Salesforce record ID to attach the document to
   * @param templateId The unique identifier of the document template to use
   * @param documentName The name for the generated document
   * @param storeInMirrexa Whether to store the document in Mirrexa (false makes it ephemeral)
   * @return Boolean indicating if the document can be attached to CRM (based on crm_able_to_attach field)
   * @example
   * Boolean canAttach = MirrexaApiService.generateAndAttachDocument(
   *     accountId, 'template123', 'Client Report', true
   * );
   */
  @AuraEnabled(cacheable=false)
  @SuppressWarnings('PMD.AvoidDebugStatements')
  public static String generateAndAttachDocument(
    Id recordId,
    String templateId,
    String documentName,
    Boolean storeInMirrexa
  ) {
    try {
      // Get the document template to determine its type
      String templateResponse = getDocumentTemplate(templateId);
      Map<String, Object> templateData = (Map<String, Object>) JSON.deserializeUntyped(
        templateResponse
      );

      if (!(Boolean) templateData.get('success')) {
        System.debug(
          LoggingLevel.ERROR,
          'Failed to retrieve document template: ' + templateResponse
        );
        return 'failed';
      }

      Map<String, Object> message = (Map<String, Object>) templateData.get(
        'message'
      );
      Map<String, Object> documentTemplate = (Map<String, Object>) message.get(
        'documentTemplate'
      );
      String templateType = (String) documentTemplate.get('type');

      // Determine Salesforce object type from recordId
      String salesforceObjectType = recordId.getSObjectType()
        .getDescribe()
        .getName();

      // Construct the payload
      Map<String, Object> payload = new Map<String, Object>{
        'name' => documentName,
        'document_template_id' => templateId,
        'is_ephemeral' => !storeInMirrexa,
        'salesforce_record_id' => recordId,
        'salesforce_object_type' => salesforceObjectType
      };

      // Call the appropriate generation method based on template type
      HttpResponse response;
      if (templateType == 'GENERAL') {
        response = generateDocument(payload);
      } else if (templateType == 'SUITABILITY_LETTER') {
        response = generateSuitabilityLetter(payload);
      } else {
        System.debug(
          LoggingLevel.ERROR,
          'Unsupported template type: ' + templateType
        );
        return 'failed';
      }

      // Check if the generation was successful and parse response
      if (response.getStatusCode() >= 200 && response.getStatusCode() < 300) {
        String responseBody = response.getBody();
        if (String.isNotBlank(responseBody)) {
          try {
            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(
              responseBody
            );
            if ((Boolean) responseData.get('success')) {
              Map<String, Object> responseMessage = (Map<String, Object>) responseData.get(
                'message'
              );
              if (
                responseMessage != null &&
                responseMessage.containsKey('crm_able_to_attach')
              ) {
                if ((Boolean) responseMessage.get('crm_able_to_attach')) {
                  return 'generated_and_attached';
                }
              }
            }
          } catch (JSONException e) {
            System.debug(
              LoggingLevel.ERROR,
              'Failed to parse API response: ' + e.getMessage()
            );
          }
        }
        return 'generated';
      } else {
        System.debug(
          LoggingLevel.ERROR,
          'Document generation failed with status: ' + response.getStatusCode()
        );
      }
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'Error initiating document generation: ' + e.getMessage()
      );
    }
    return 'failed';
  }

  /**
   * @description Automatically registers the current user with Mirrexa by gathering required parameters.
   *              This method is idempotent and safe to call multiple times.
   *              Includes comprehensive security checks for CRUD and FLS permissions.
   * @return String containing registration response from Mirrexa API
   * @throws AuraHandledException if user lacks sufficient permissions or registration fails
   * @example
   * String result = MirrexaApiService.autoRegisterUser();
   * // User is now registered with Mirrexa platform
   */
  @AuraEnabled(cacheable=false)
  @SuppressWarnings('PMD.AvoidDebugStatements')
  public static String autoRegisterUser() {
    try {
      // Check FLS for User object
      if (!Schema.sObjectType.User.isAccessible()) {
        throw new AuraHandledException(
          'Insufficient permissions to access User records'
        );
      }

      // Check field-level security for User fields
      if (
        !Schema.sObjectType.User.fields.Id.isAccessible() ||
        !Schema.sObjectType.User.fields.Username.isAccessible()
      ) {
        throw new AuraHandledException(
          'Insufficient field permissions for User records'
        );
      }

      // Check FLS for Organization object
      if (!Schema.sObjectType.Organization.isAccessible()) {
        throw new AuraHandledException(
          'Insufficient permissions to access Organization records'
        );
      }

      // Check field-level security for Organization fields
      if (!Schema.sObjectType.Organization.fields.InstanceName.isAccessible()) {
        throw new AuraHandledException(
          'Insufficient field permissions for Organization records'
        );
      }

      // Get current user information
      List<User> currentUserList = [
        SELECT Id, Username
        FROM User
        WHERE Id = :UserInfo.getUserId()
        LIMIT 1
      ];

      if (currentUserList.isEmpty()) {
        throw new AuraHandledException('Current user not found');
      }

      User currentUser = currentUserList[0];

      // Construct instance URL
      String instanceUrl = URL.getOrgDomainUrl().toExternalForm();

      // Call the registerUser method with gathered parameters
      return registerUser(instanceUrl, currentUser.Username, currentUser.Id);
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'Failed to auto-register user: ' + e.getMessage()
      );
      throw new AuraHandledException(
        'Error auto-registering user: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Retrieves subscription information from the Mirrexa API.
   *              Returns details about product types, subscription levels, usage limits, and metadata.
   * @return String containing JSON response with subscription details including:
   *         - Product types (ai-documents, suitability-letter, top-up-letter, client-income-report)
   *         - Product sub types (trial, basic, pro)
   *         - Usage limits and metadata
   * @throws AuraHandledException if API call fails or returns invalid response
   * @example
   * String subscriptions = MirrexaApiService.getSubscriptions();
   * Map<String, Object> subData = (Map<String, Object>) JSON.deserializeUntyped(subscriptions);
   */
  @AuraEnabled(cacheable=false)
  @SuppressWarnings('PMD.AvoidDebugStatements')
  public static String getSubscriptions() {
    try {
      HttpRequest req = new HttpRequest();
      String ncDevName9 = resolveNamedCredentialDevName('Mirrexa_API');
      req.setEndpoint('callout:' + ncDevName9 + '/api/subscriptions');
      req.setMethod('GET');
      req.setHeader('Content-Type', 'application/json;charset=UTF-8');

      Http http = new Http();
      HttpResponse res = http.send(req);

      if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
        return res.getBody();
      } else {
        throw new AuraHandledException(
          'Failed to fetch subscription data: ' +
            res.getStatus() +
            ' - ' +
            res.getBody()
        );
      }
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'Failed to fetch subscription data: ' + e.getMessage()
      );
      throw new AuraHandledException(
        'Error fetching subscription data: ' + e.getMessage()
      );
    }
  }
}
