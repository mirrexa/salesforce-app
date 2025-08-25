# Mirrexa - Data Classification Guide

## Overview

This document provides detailed information about data classification, handling, and protection for the Mirrexa Salesforce AppExchange application. It outlines what data is processed, how it's classified, and the security controls applied to each classification level.

## Data Classification Framework

### Classification Levels

#### Public
- **Definition**: Information that can be freely shared without risk
- **Examples**: Company names, public contact information, general business descriptions
- **Protection Requirements**: Standard security controls
- **Retention**: No specific retention requirements

#### Internal
- **Definition**: Information intended for internal use within the organization
- **Examples**: Client relationship data, internal contact information, business processes
- **Protection Requirements**: Access controls, encryption in transit
- **Retention**: Standard business retention policies

#### Confidential
- **Definition**: Sensitive information that could cause harm if disclosed
- **Examples**: Client financial information, personal details, account balances
- **Protection Requirements**: Strong access controls, encryption, audit logging
- **Retention**: Limited retention, secure disposal

#### Restricted
- **Definition**: Highly sensitive information requiring maximum protection
- **Examples**: Social security numbers, bank account details, health information
- **Protection Requirements**: Highest security controls, minimal access, comprehensive logging
- **Retention**: Minimal retention, immediate secure disposal

## Data Types and Classification

### Client Information

#### Personal Identifiers
- **Data Type**: Names, addresses, phone numbers, email addresses
- **Classification**: Confidential
- **Usage**: Document personalization and contact information
- **Retention**: Processed temporarily, not stored
- **Protection**: TLS encryption, access controls

#### Financial Information
- **Data Type**: Account balances, investment details, financial goals
- **Classification**: Confidential to Restricted (depending on specificity)
- **Usage**: Financial document generation and reporting
- **Retention**: Not stored, processed in memory only
- **Protection**: End-to-end encryption, strict access controls

#### Business Information
- **Data Type**: Company details, business relationships, preferences
- **Classification**: Internal to Confidential
- **Usage**: Business document generation and customization
- **Retention**: Temporary processing only
- **Protection**: Standard security controls, access logging

### System Information

#### Authentication Data
- **Data Type**: OAuth tokens, session identifiers
- **Classification**: Restricted
- **Usage**: API authentication and authorization
- **Retention**: Token lifetime only
- **Protection**: Secure token storage, automatic expiration

#### Audit Information
- **Data Type**: Access logs, usage patterns, error logs
- **Classification**: Internal
- **Usage**: Security monitoring and troubleshooting
- **Retention**: Standard log retention periods
- **Protection**: Access controls, secure storage

## Data Processing Activities

### Document Generation Process

#### Data Collection
1. **Source**: Salesforce records (Accounts, Contacts, etc.)
2. **Method**: API calls using authenticated connections
3. **Scope**: Only fields necessary for document generation
4. **Validation**: Data validated before transmission

#### Data Transmission
1. **Protocol**: HTTPS with TLS 1.2 or higher
2. **Authentication**: OAuth 2.0 tokens
3. **Encryption**: End-to-end encryption
4. **Validation**: Certificate validation enforced

#### Data Processing
1. **Location**: Mirrexa platform servers
2. **Duration**: Temporary processing only
3. **Purpose**: Document generation and formatting
4. **Storage**: No persistent storage of client data

#### Data Return
1. **Format**: Generated documents (PDF, Word, etc.)
2. **Delivery**: Direct download to user's browser
3. **Storage**: Documents stored locally by user
4. **Cleanup**: Temporary data automatically purged

### Authentication Process

#### OAuth Flow
1. **User Initiation**: User clicks authentication button
2. **Redirect**: Secure redirect to Mirrexa OAuth endpoint
3. **Authorization**: User authorizes application access
4. **Token Exchange**: Secure token exchange
5. **Token Storage**: Tokens stored in Salesforce Named Credentials

#### Token Management
1. **Storage**: Salesforce platform secure storage
2. **Encryption**: Platform-level encryption
3. **Access**: Per-user token isolation
4. **Refresh**: Automatic token refresh
5. **Expiration**: Configurable token expiration

## Data Handling Requirements

### By Classification Level

#### Public Data
- **Access**: No special restrictions
- **Transmission**: Standard HTTPS
- **Storage**: Standard security controls
- **Disposal**: Standard deletion procedures

#### Internal Data
- **Access**: Authenticated users only
- **Transmission**: Encrypted in transit
- **Storage**: Access-controlled storage
- **Disposal**: Secure deletion procedures

#### Confidential Data
- **Access**: Authorized users with business need
- **Transmission**: End-to-end encryption
- **Storage**: Encrypted storage with access logging
- **Disposal**: Secure overwriting or destruction

#### Restricted Data
- **Access**: Minimal access, strong authentication
- **Transmission**: Highest encryption standards
- **Storage**: Encrypted with key management
- **Disposal**: Cryptographic erasure or physical destruction

### Cross-Border Data Transfer

#### Data Residency
- **Processing Location**: Cloudflare (Global)
- **Legal Framework**: Appropriate legal frameworks for data transfer
- **Compliance**: Compliance with local data protection laws
- **Safeguards**: Appropriate safeguards for international transfers

#### Transfer Mechanisms
- **Legal Basis**: Legitimate business interests
- **Safeguards**: Standard contractual clauses or adequacy decisions
- **User Consent**: Where required by law
- **Transparency**: Clear information about data transfers

## Compliance Requirements

### Regulatory Compliance

#### GDPR (General Data Protection Regulation)
- **Lawful Basis**: Legitimate interests for document generation
- **Data Subject Rights**: Mechanisms for exercising rights
- **Privacy by Design**: Built-in privacy protections
- **Data Protection Officer**: Contact information available

#### CCPA (California Consumer Privacy Act)
- **Consumer Rights**: Rights to know, delete, and opt-out
- **Business Purpose**: Document generation for business purposes
- **Service Provider**: Mirrexa acts as service provider
- **Data Sales**: No sale of personal information

#### Industry Standards
- **SOC 2**: Service Organization Control 2 compliance
- **ISO 27001**: Information security management
- **NIST**: National Institute of Standards and Technology framework
- **PCI DSS**: If payment card data is processed

### Organizational Policies

#### Data Governance
- **Data Stewardship**: Clear data ownership and stewardship
- **Policy Compliance**: Adherence to organizational data policies
- **Risk Assessment**: Regular data risk assessments
- **Training**: Data handling training for users

#### Privacy Policies
- **Transparency**: Clear privacy notices
- **Consent Management**: Appropriate consent mechanisms
- **Rights Management**: Processes for exercising data rights
- **Breach Response**: Data breach response procedures

## Security Controls by Data Type

### Technical Controls

#### Encryption
- **In Transit**: TLS 1.2 or higher for all communications
- **At Rest**: AES-256 encryption for stored authentication tokens
- **Key Management**: Secure key management practices
- **Certificate Management**: Regular certificate rotation

#### Access Controls
- **Authentication**: Multi-factor authentication where possible
- **Authorization**: Role-based access control
- **Principle of Least Privilege**: Minimal necessary access
- **Regular Reviews**: Periodic access reviews

#### Monitoring
- **Activity Logging**: Comprehensive activity logging
- **Anomaly Detection**: Automated anomaly detection
- **Incident Response**: Rapid incident response procedures
- **Audit Trails**: Complete audit trails for sensitive operations

### Administrative Controls

#### Policies and Procedures
- **Data Handling**: Clear data handling procedures
- **Security Policies**: Comprehensive security policies
- **Incident Response**: Incident response procedures
- **Training**: Regular security training

#### Risk Management
- **Risk Assessments**: Regular risk assessments
- **Threat Modeling**: Application threat modeling
- **Vulnerability Management**: Systematic vulnerability management
- **Business Continuity**: Business continuity planning

### Physical Controls

#### Data Centers
- **Physical Security**: Secure data center facilities
- **Access Controls**: Restricted physical access
- **Environmental Controls**: Appropriate environmental controls
- **Redundancy**: Redundant systems and facilities

## Data Subject Rights

### Individual Rights

#### Right to Information
- **Transparency**: Clear information about data processing
- **Privacy Notices**: Comprehensive privacy notices
- **Contact Information**: Clear contact information for inquiries
- **Processing Purposes**: Clear explanation of processing purposes

#### Right of Access
- **Data Portability**: Data provided in machine-readable format
- **Response Time**: Timely responses to access requests
- **Identity Verification**: Secure identity verification procedures
- **Scope**: Clear scope of data provided

#### Right to Rectification
- **Correction Procedures**: Procedures for correcting inaccurate data
- **Data Quality**: Measures to ensure data quality
- **Notification**: Notification of corrections to relevant parties
- **Timeliness**: Timely correction of inaccurate data

#### Right to Erasure
- **Deletion Procedures**: Secure deletion procedures
- **Retention Policies**: Clear data retention policies
- **Technical Implementation**: Technical measures for data erasure
- **Verification**: Verification of data deletion

### Exercising Rights

#### Request Process
1. **Contact**: Contact information for data rights requests
2. **Verification**: Identity verification procedures
3. **Assessment**: Assessment of request validity
4. **Response**: Timely response to requests
5. **Follow-up**: Follow-up on request resolution

#### Contact Information
- **Data Protection Officer**: team@mirrexa.ai
- **Privacy Team**: team@mirrexa.ai
- **Support**: team@mirrexa.ai

## Conclusion

This data classification guide provides a comprehensive framework for understanding and managing data within the Mirrexa application. All stakeholders should familiarize themselves with these classifications and requirements to ensure proper data handling and compliance.

### Updates and Reviews

- **Regular Reviews**: This document is reviewed annually
- **Updates**: Updates made as needed for regulatory changes
- **Training**: Regular training on data classification requirements
- **Compliance**: Ongoing compliance monitoring and assessment

---

**Document Version**: 1.0  
**Last Updated**: 2025-07-17  
**Next Review**: 2026-07-17  
**Owner**: team@mirrexa.ai  
**Approved By**: team@mirrexa.ai
