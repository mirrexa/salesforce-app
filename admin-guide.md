# Mirrexa - Administrator Guide

## Overview

This guide provides comprehensive information for Salesforce administrators managing the Mirrexa application. It covers ongoing administration, user management, troubleshooting, and best practices.

## User Management

### Permission Sets

#### Mirrexa_App_Access_2GP Permission Set
The "Mirrexa_App_Access_2GP" permission set controls access to the Mirrexa functionality.

**Included Permissions:**
- Access to Lightning Web Components
- External Credential Principal Access for MirrexaOAuth
- API permissions for document generation
- [TODO: List specific permissions included]

**Assignment Process:**
1. Navigate to **Setup → Users → Permission Sets**
2. Select "Mirrexa_App_Access_2GP"
3. Click "Manage Assignments"
4. Add users who need access to the application

**Best Practices:**
- Assign to users who actively generate client documents
- Review assignments quarterly
- Remove access for inactive users
- Consider creating custom permission sets for different user roles

### User Onboarding

#### New User Setup Checklist
- [ ] Assign "Mirrexa_App_Access_2GP" permission set
- [ ] Add user to relevant Lightning App or pages
- [ ] Provide user training materials
- [ ] Test OAuth authentication
- [ ] Verify document generation access

#### User Training
- Share the [User Guide](user-guide.md) with new users
- Conduct training sessions on OAuth authentication
- Demonstrate document generation workflow
- Provide troubleshooting contact information

## Configuration Management

### OAuth Configuration

#### External Credentials
**MirrexaOAuth External Credential:**
- Location: Setup → Security → Named Credentials → External Credentials
- Authentication Protocol: OAuth 2.0
- Authentication Flow URL: https://mirrexa.ai/oauth-client/authorize
- Token Endpoint URL: https://api.mirrexa.ai/api/oauth/token

**Monitoring:**
- Review authentication logs regularly
- Monitor token refresh patterns
- Check for authentication failures

#### Named Credentials
**Mirrexa_API Named Credential:**
- URL: `https://api.mirrexa.ai`
- Identity Type: Per User
- Authentication Protocol: OAuth 2.0
- External Credential: MirrexaOAuth

**Maintenance:**
- Verify endpoint availability
- Monitor API response times
- Review error logs for API issues

### Connected App Management

#### Mirrexa Connected App
- Location: Setup → Apps → App Manager
- OAuth Settings: Configured for external authentication
- Callback URLs: Configured for OAuth flow

**Security Settings:**
- Review permitted users regularly
- Monitor OAuth usage patterns
- Update security policies as needed

### Remote Site Settings

#### Required Remote Sites
1. **Mirrexa_Auth_API**
   - URL: `https://api.mirrexa.ai`
   - Purpose: API communication
   - Status: Must remain active

2. **Mirrexa_Web**
   - URL: `https://mirrexa.ai`
   - Purpose: OAuth authentication
   - Status: Must remain active

**Maintenance:**
- Verify sites remain active
- Monitor for SSL certificate changes
- Update URLs if endpoints change

## Monitoring and Maintenance

### System Health Checks

#### Daily Monitoring
- [ ] Check for authentication failures in debug logs
- [ ] Monitor API response times
- [ ] Review user-reported issues

#### Weekly Reviews
- [ ] Analyze usage patterns
- [ ] Review permission set assignments
- [ ] Check for system updates or patches

#### Monthly Maintenance
- [ ] Review OAuth token refresh patterns
- [ ] Analyze performance metrics
- [ ] Update documentation as needed
- [ ] Review security settings

### Performance Monitoring

#### Key Metrics to Track
- Authentication success rate
- Document generation response times
- API error rates
- User adoption metrics

#### Monitoring Tools
- Salesforce Event Monitoring (if available)
- Debug logs for error tracking
- Custom logging in Apex classes
- User feedback and support tickets

### Debug and Logging

#### Enable Debug Logging
1. Navigate to **Setup → Environments → Logs → Debug Logs**
2. Click "New" to create a debug log
3. Select user and set log levels:
   - Apex Code: DEBUG
   - Callout: DEBUG
   - System: INFO

#### Common Log Patterns
- OAuth authentication flows
- API callout responses
- Permission-related errors
- Component loading issues

## Troubleshooting

### Common Issues and Solutions

#### Authentication Problems

**Issue**: Users cannot authenticate with Mirrexa
**Symptoms**: OAuth popup fails or shows errors
**Solutions**:
1. Verify Remote Site Settings are active
2. Check External Credential configuration
3. Ensure Named Credential is properly configured
4. Review Connected App settings
5. Check user permission assignments

**Issue**: Authentication succeeds but API calls fail
**Symptoms**: Document generation fails after authentication
**Solutions**:
1. Verify Named Credential endpoint URL
2. Check API service availability
3. Review External Credential token settings
4. Examine debug logs for API errors

#### Component Issues

**Issue**: Component not visible to users
**Symptoms**: Users cannot find or access the component
**Solutions**:
1. Verify permission set assignment
2. Check Lightning page configuration
3. Ensure component is added to appropriate pages
4. Review profile permissions

**Issue**: Component loads but shows errors
**Symptoms**: Component displays error messages
**Solutions**:
1. Check debug logs for JavaScript errors
2. Verify API connectivity
3. Review authentication status
4. Check for missing dependencies

### Escalation Process

#### Level 1: Self-Service
- Review this administrator guide
- Check debug logs and error messages
- Verify configuration settings
- Test with different users

#### Level 2: Support Contact
- Gather debug logs and error details
- Document steps to reproduce issue
- Contact support with org ID and details
- Email: team@mirrexa.ai

#### Level 3: Emergency Support
- For critical production issues
- Contact: team@mirrexa.ai
- Include: Org ID, user count affected, business impact

## Security and Compliance

### Security Best Practices

#### Access Control
- Regularly review permission set assignments
- Implement least-privilege access principles
- Monitor for unauthorized access attempts
- Remove access for inactive users

#### Data Protection
- Understand data flow between Salesforce and Mirrexa
- Review data retention policies
- Ensure compliance with privacy regulations
- Monitor for data exposure risks

#### OAuth Security
- Regularly review OAuth token usage
- Monitor for suspicious authentication patterns
- Keep Connected App settings secure
- Review callback URLs periodically

### Compliance Considerations

#### Data Classification
- Review [Data Classification Guide](data-classification.md)
- Understand what data is transmitted to Mirrexa
- Ensure compliance with organizational policies
- Document data handling procedures

#### Privacy Requirements
- Review [Privacy Policy](privacy-policy.md)
- Understand data processing activities
- Ensure user consent where required
- Maintain audit trails

## Backup and Recovery

### Configuration Backup

#### Critical Components to Backup
- Permission set configurations
- Named Credential settings
- External Credential configurations
- Connected App settings
- Remote Site Settings

#### Backup Process
1. Export metadata using Salesforce CLI or Workbench
2. Document custom configurations
3. Store backups in version control
4. Test restore procedures regularly

### Disaster Recovery

#### Recovery Procedures
1. Reinstall package if necessary
2. Restore configuration from backups
3. Reassign permission sets
4. Test authentication and functionality
5. Communicate with users about restoration

## Updates and Upgrades

### Package Updates

#### Update Process
1. Review release notes in [CHANGELOG.md](CHANGELOG.md)
2. Test updates in sandbox environment
3. Schedule maintenance window
4. Install updates in production
5. Verify functionality post-update
6. Communicate changes to users

#### Rollback Procedures
- Document current configuration before updates
- Test rollback procedures in sandbox
- Have rollback plan ready for production
- Monitor for issues post-update

## Support and Resources

### Documentation
- [Installation Guide](install-guide.md)
- [User Guide](user-guide.md)
- [Security Review](security-review.md)
- [Data Classification](data-classification.md)

### Support Channels
- **Email**: team@mirrexa.ai
- **Documentation**: [TODO: Add documentation URL]
- **Support Portal**: [TODO: Add support portal URL]

### Training Resources
- Administrator training materials
- User training guides
- Video tutorials (if available)
- Best practices documentation

---

**Questions?** Contact our support team for assistance with administration and configuration.
