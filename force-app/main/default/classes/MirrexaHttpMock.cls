@IsTest
public class MirrexaHttpMock implements HttpCalloutMock {
  public static Integer nextStatusCode;
  public static String nextBody;
  public static Boolean nextAttachAllowed;
  public static List<String> callLog = new List<String>();

  public HttpResponse respond(HttpRequest req) {
    HttpResponse res = new HttpResponse();

    // Default values
    Boolean hadExplicitStatus = (nextStatusCode != null);
    Boolean hadExplicitBody = (nextBody != null);
    Integer statusCode = hadExplicitStatus ? nextStatusCode : 200;
    String body = nextBody;

    // Reset after consumption so each test can set anew
    nextStatusCode = null;
    nextBody = null; // IMPORTANT: do not leak the template GET body into subsequent POSTs

    String endpoint = req.getEndpoint();
    String method = req.getMethod();

    // Provide sensible defaults per endpoint if not explicitly overridden by test
    if (endpoint != null && endpoint.contains('callout:Mirrexa_API')) {
      // Hard-coded specific template matches first for reliability
      if (method == 'GET' && endpoint.contains('/api/document-templates/tmpl-general')) {
        if (!hadExplicitStatus) statusCode = 200;
        if (body == null) body = '{"success":true,"message":{"documentTemplate":{"id":"tmpl-general","type":"GENERAL"}}}';
      } else if (method == 'GET' && endpoint.contains('/api/document-templates/tmpl-suit')) {
        if (!hadExplicitStatus) statusCode = 200;
        if (body == null) body = '{"success":true,"message":{"documentTemplate":{"id":"tmpl-suit","type":"SUITABILITY_LETTER"}}}';
      } else if (method == 'GET' && endpoint.contains('/api/document-templates/tmpl-unknown')) {
        if (!hadExplicitStatus) statusCode = 200;
        if (body == null) body = '{"success":true,"message":{"documentTemplate":{"id":"tmpl-unknown","type":"UNKNOWN"}}}';
      } else 
      if (endpoint.endsWith('/api/user') && method == 'GET') {
        if (!hadExplicitStatus) statusCode = 200;
        if (body == null) body = '{"id":"user-1","email":"u@example.com"}';
      } else if (endpoint.contains('/api/document-templates') && method == 'GET') {
        // Robust handling for both list and specific template GETs
        Integer idx = endpoint.indexOf('/api/document-templates/');
        if (idx != -1) {
          String rest = endpoint.substring(idx + '/api/document-templates/'.length());
          // Extract the id up to next '/' or '?' if present
          Integer slashPos = rest.indexOf('/');
          Integer qPos = rest.indexOf('?');
          Integer endPos;
          if (slashPos == -1 && qPos == -1) {
            endPos = rest.length();
          } else if (slashPos == -1) {
            endPos = qPos;
          } else if (qPos == -1) {
            endPos = slashPos;
          } else {
            endPos = Math.min(slashPos, qPos);
          }
          String idPart = rest.substring(0, endPos);
          if (!hadExplicitStatus) statusCode = 200;
          if (idPart == 'tmpl-general') {
            if (body == null) body = '{"success":true,"message":{"documentTemplate":{"id":"tmpl-general","type":"GENERAL"}}}';
          } else if (idPart == 'tmpl-suit') {
            if (body == null) body = '{"success":true,"message":{"documentTemplate":{"id":"tmpl-suit","type":"SUITABILITY_LETTER"}}}';
          } else if (idPart == 'tmpl-unknown') {
            if (body == null) body = '{"success":true,"message":{"documentTemplate":{"id":"tmpl-unknown","type":"UNKNOWN"}}}';
          } else if (String.isBlank(idPart)) {
            // list endpoint (trailing slash)
            if (body == null) body = '{"success":true,"message":{"items":[]}}';
          } else {
            if (!hadExplicitStatus) statusCode = 404;
            body = '{"success":false,"message":"not found"}';
          }
        } else {
          // list endpoint without specific id
          if (!hadExplicitStatus) statusCode = 200;
          if (body == null) body = '{"success":true,"message":{"items":[]}}';
        }
      } else if (endpoint.contains('/api/document-templates/') && method == 'DELETE') {
        Integer idx2 = endpoint.indexOf('/api/document-templates/');
        Boolean ok = false;
        if (idx2 != -1) {
          String rest2 = endpoint.substring(idx2 + '/api/document-templates/'.length());
          ok = rest2.length() > 0 && !rest2.contains('/');
        }
        if (ok) {
        if (!hadExplicitStatus) statusCode = 200;
        if (body == null) body = '{"success":true,"message":"deleted"}';
        }
      } else if (endpoint.endsWith('/toggle-share') && method == 'POST') {
        if (!hadExplicitStatus) statusCode = 200;
        if (body == null) body = '{"success":true,"message":"toggled"}';
      } else if (endpoint.endsWith('/api/document-templates') && method == 'POST') {
        if (!hadExplicitStatus) statusCode = 200;
        if (body == null) body = '{"success":true,"message":{"id":"new-tmpl"}}';
      } else if (endpoint.endsWith('/api/salesforce/register-user') && method == 'POST') {
        if (!hadExplicitStatus) statusCode = 200;
        if (body == null) body = '{"success":true,"message":"registered"}';
      } else if (endpoint.endsWith('/api/subscriptions') && method == 'GET') {
        if (!hadExplicitStatus) statusCode = 200;
        if (body == null) body = '{"success":true,"message":{"products":[]}}';
      } else if (endpoint.endsWith('/api/documents') && method == 'POST') {
        Boolean attach = nextAttachAllowed == null ? true : nextAttachAllowed;
        if (!hadExplicitStatus) statusCode = 200;
        if (body == null) body = '{"success":true,"message":{"crm_able_to_attach":' + String.valueOf(attach) + '}}';
        nextAttachAllowed = null;
      } else if (endpoint.endsWith('/api/suitability-letters') && method == 'POST') {
        Boolean attach2 = nextAttachAllowed == null ? true : nextAttachAllowed;
        if (!hadExplicitStatus) statusCode = 200;
        if (body == null) body = '{"success":true,"message":{"crm_able_to_attach":' + String.valueOf(attach2) + '}}';
        nextAttachAllowed = null;
      }
    }

    // Fallbacks to make tests resilient if any of the above checks miss
    if (method == 'GET' && endpoint != null && endpoint.contains('/api/document-templates/') && body == null) {
      if (!hadExplicitStatus) statusCode = 200;
      body = '{"success":true,"message":{"documentTemplate":{"id":"tmpl-general","type":"GENERAL"}}}';
    }

    res.setStatusCode(statusCode);
    res.setBody(body == null ? '{"ok":true}' : body);
    res.setHeader('Content-Type', 'application/json');
    // Log the call for debugging within tests
    try {
      callLog.add(method + ' ' + endpoint + ' -> ' + String.valueOf(statusCode) + ' body=' + (body == null ? '{"ok":true}' : body));
    } catch (Exception e) {
      // ignore logging failures
    }
    return res;
  }
}
