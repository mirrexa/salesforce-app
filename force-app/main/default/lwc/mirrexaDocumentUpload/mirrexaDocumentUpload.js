import { LightningElement, track, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { publish, MessageContext } from "lightning/messageService";
import REFRESH_TEMPLATES_CHANNEL from "@salesforce/messageChannel/RefreshTemplates__c";
import createDocumentTemplate from "@salesforce/apex/MirrexaApiService.createDocumentTemplate";
import getUserData from "@salesforce/apex/MirrexaApiService.getUserData";

export default class MirrexaDocumentUpload extends LightningElement {
  @wire(MessageContext)
  messageContext;

  @track templateName = "";
  @track templateDescription = "";
  @track templateType = "GENERAL";
  @track availableToOrganisation = false;
  @track selectedFile = null;
  @track selectedFileName = "";
  @track isUploading = false;
  @track successMessage = "";
  @track errorMessage = "";
  @track userData = null;
  @track showTypeField = false;
  @track isLoadingUserData = true;
  @track isConnected = false;
  @track isNotAllowed = false;

  typeOptions = [
    { label: "General", value: "GENERAL" },
    { label: "Suitability Letter", value: "SUITABILITY_LETTER" }
  ];

  connectedCallback() {
    this.isLoadingUserData = true;
  }

  async loadUserData() {
    try {
      this.isLoadingUserData = true;
      const response = await getUserData();
      const result = JSON.parse(response);

      if (result.success) {
        this.userData = result.message;
        // Show type field only if user has suitability-letter set to true
        this.showTypeField =
          result.message.products &&
          result.message.products["suitability-letter"] === true;

        // If type field is not shown, ensure templateType is set to GENERAL
        if (!this.showTypeField) {
          this.templateType = "GENERAL";
        }
      } else {
        console.error("Failed to load user data:", result.message);
        // Default to not showing type field if we can't load user data
        this.showTypeField = false;
        this.templateType = "GENERAL";
      }
    } catch (error) {
      console.error("Error loading user data:", error);
      // Default to not showing type field if there's an error
      this.showTypeField = false;
      this.templateType = "GENERAL";
    } finally {
      this.isLoadingUserData = false;
    }
  }

  handleNameChange(event) {
    this.templateName = event.target.value;
    this.clearMessages();
  }

  handleDescriptionChange(event) {
    this.templateDescription = event.target.value;
    this.clearMessages();
  }

  handleTypeChange(event) {
    this.templateType = event.detail.value;
    this.clearMessages();
  }

  handleOrganisationChange(event) {
    this.availableToOrganisation = event.target.checked;
    this.clearMessages();
  }

  handleFileChange(event) {
    const file = event.target.files[0];
    if (file) {
      this.selectedFile = file;
      this.selectedFileName = file.name;
      this.clearMessages();
    }
  }

  clearMessages() {
    this.successMessage = "";
    this.errorMessage = "";
  }

  validateForm() {
    if (!this.templateName.trim()) {
      this.errorMessage = "Please enter a template name.";
      return false;
    }

    if (!this.templateDescription.trim()) {
      this.errorMessage = "Please enter a template description.";
      return false;
    }

    if (!this.selectedFile) {
      this.errorMessage = "Please select a document file.";
      return false;
    }

    // Validate file type
    const allowedTypes = [
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" // .docx
    ];

    if (!allowedTypes.includes(this.selectedFile.type)) {
      this.errorMessage = "Please select a valid Word document (.docx).";
      return false;
    }

    return true;
  }

  async handleUpload() {
    this.clearMessages();

    if (!this.validateForm()) {
      return;
    }

    this.isUploading = true;

    try {
      // Convert file to base64
      const base64FileData = await this.fileToBase64(this.selectedFile);

      // Prepare payload - only include type if showTypeField is true
      const payload = {
        name: this.templateName,
        description: this.templateDescription,
        base64FileData: base64FileData,
        availableToOrganisation: this.availableToOrganisation
      };

      // Only include type if the field is shown (sjp is true)
      if (this.showTypeField) {
        payload.type = this.templateType;
      }
      // If not shown, the backend will default to 'GENERAL'

      // Call Apex method
      const response = await createDocumentTemplate(payload);

      // Parse response
      const result = JSON.parse(response);

      if (result.success) {
        this.successMessage = `Template "${result.message.name}" uploaded successfully!`;
        this.resetForm();

        // Show toast notification
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Success",
            message: "Document template uploaded successfully",
            variant: "success"
          })
        );

        // Dispatch refresh event to update template list
        publish(this.messageContext, REFRESH_TEMPLATES_CHANNEL, {
          action: "refresh"
        });
      } else {
        this.errorMessage =
          "Upload failed: " + (result.message || "Unknown error");
      }
    } catch (error) {
      console.error("Upload error:", error);
      this.errorMessage =
        "Upload failed: " +
        (error.body?.message || error.message || "Unknown error");

      // Show toast notification for error
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error",
          message: "Failed to upload document template",
          variant: "error"
        })
      );
    } finally {
      this.isUploading = false;
    }
  }

  fileToBase64(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.readAsDataURL(file);
      reader.onload = () => {
        // Remove the data URL prefix (e.g., "data:application/pdf;base64,")
        const base64String = reader.result.split(",")[1];
        resolve(base64String);
      };
      reader.onerror = (error) => reject(error);
    });
  }

  resetForm() {
    this.templateName = "";
    this.templateDescription = "";
    this.templateType = "GENERAL";
    this.availableToOrganisation = false;
    this.selectedFile = null;
    this.selectedFileName = "";

    // Reset file input
    const fileInput = this.template.querySelector(
      'lightning-input[type="file"]'
    );
    if (fileInput) {
      fileInput.value = "";
    }
  }

  // Event handlers for connection status component
  handleConnectionStatusChange(event) {
    const { isConnected, isNotAllowed, statusChanged } = event.detail;
    this.isConnected = isConnected;
    this.isNotAllowed = isNotAllowed;

    if (statusChanged && isConnected) {
      // Load user data when connection is established
      this.loadUserData();
    } else if (!isConnected) {
      // Reset state when disconnected
      this.userData = null;
      this.showTypeField = false;
      this.isLoadingUserData = false;
    }
  }

  handleConnectionError(event) {
    const { error } = event.detail;
    this.showToast("Connection Error", this.getErrorMessage(error), "error");
    this.isLoadingUserData = false;
  }

  handleUserRegistered() {
    console.log("User successfully registered with Mirrexa");
    this.loadUserData();
  }

  async refreshConnectionStatus() {
    // Delegate to the connection status component
    const connectionComponent = this.template.querySelector(
      "c-mirrexa-connection-status"
    );
    if (connectionComponent) {
      await connectionComponent.refreshConnectionStatus();
    }
  }
}