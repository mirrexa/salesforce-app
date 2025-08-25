import getDocumentTemplates from "@salesforce/apex/MirrexaApiService.getDocumentTemplates";
import getDocumentTemplate from "@salesforce/apex/MirrexaApiService.getDocumentTemplate";
import deleteDocumentTemplate from "@salesforce/apex/MirrexaApiService.deleteDocumentTemplate";
import toggleDocumentTemplateShare from "@salesforce/apex/MirrexaApiService.toggleDocumentTemplateShare";
import getUserData from "@salesforce/apex/MirrexaApiService.getUserData";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { LightningElement, track, wire } from "lwc";
import { subscribe, MessageContext } from "lightning/messageService";
import REFRESH_TEMPLATES_CHANNEL from "@salesforce/messageChannel/RefreshTemplates__c";

export default class MirrexaTemplatesList extends LightningElement {
  @wire(MessageContext)
  messageContext;

  subscription = null;

  @track templates = [];
  @track isLoading = true;
  @track error;
  @track userData = null;
  @track userHasOrganisation = false;
  @track isConnected = false;
  @track isNotAllowed = false;

  // Pagination state
  @track currentPage = 0;
  @track totalPages = 0;
  @track itemsPerPage = 50;
  @track totalItems = 0;

  get columns() {
    const baseColumns = [
      {
        label: "Template Name",
        fieldName: "name",
        type: "text",
        sortable: true
      },
      {
        label: "Description",
        fieldName: "description",
        type: "text",
        wrapText: true
      },
      {
        label: "Type",
        fieldName: "type",
        type: "text",
        sortable: true
      },
      {
        label: "Shared",
        fieldName: "shared",
        type: "text",
        sortable: true
      },
      {
        label: "Created Date",
        fieldName: "createdAt",
        type: "text",
        sortable: true
      },
      {
        label: "Created By",
        fieldName: "createdBy",
        type: "text",
        sortable: true
      }
    ];

    // Build row actions based on organization membership
    const rowActions = [
      {
        label: "Download",
        name: "download",
        iconName: "utility:download"
      }
    ];

    // Add conditional Share/Unshare action if user has organization
    if (this.userHasOrganisation) {
      rowActions.push({
        label: "Share",
        name: "share",
        iconName: "utility:share"
      });
      rowActions.push({
        label: "Unshare",
        name: "unshare",
        iconName: "utility:unshare"
      });
    }

    rowActions.push({
      label: "Delete",
      name: "delete",
      iconName: "utility:delete"
    });

    baseColumns.push({
      type: "action",
      typeAttributes: {
        rowActions: rowActions
      }
    });

    return baseColumns;
  }

  connectedCallback() {
    this.subscribeToMessageChannel();
    this.isLoading = true;
  }

  disconnectedCallback() {
    this.unsubscribeFromMessageChannel();
  }

  subscribeToMessageChannel() {
    if (!this.subscription) {
      this.subscription = subscribe(
        this.messageContext,
        REFRESH_TEMPLATES_CHANNEL,
        (message) => this.handleMessage(message)
      );
    }
  }

  unsubscribeFromMessageChannel() {
    if (this.subscription) {
      this.subscription = null;
    }
  }

  handleMessage(message) {
    if (message.action === "refresh") {
      this.handleRefresh();
    }
  }

  async loadUserData() {
    try {
      const response = await getUserData();
      const data = JSON.parse(response);

      if (data.success && data.message) {
        this.userData = data.message;
        // Check if user has an organisation_id to determine if they can share/unshare
        this.userHasOrganisation = !!data.message.organisation_id;
      } else {
        console.error("Failed to load user data:", data);
        this.userHasOrganisation = false;
      }
    } catch (error) {
      console.error("Error loading user data:", error);
      this.userHasOrganisation = false;
    }
  }

  async loadTemplates(page = 0, limit = this.itemsPerPage) {
    this.isLoading = true;
    this.error = null;

    try {
      const response = await getDocumentTemplates({ page, limit });
      const data = JSON.parse(response);

      if (data.success && data.message && data.message.data) {
        // Create a lookup map for users
        const usersMap = new Map();
        if (data.message.relatedData && data.message.relatedData.users) {
          data.message.relatedData.users.forEach((user) => {
            usersMap.set(user.id, user.name || user.email || "Unknown User");
          });
        }

        this.templates = data.message.data.map((template) => ({
          id: template.id,
          name: template.name,
          description: template.description,
          type: this.formatType(template.type),
          shared: template.organisation_id !== null ? "Yes" : "No",
          createdAt: new Date(template.created_at).toLocaleDateString(),
          createdBy: usersMap.get(template.user_id) || "Unknown User"
        }));

        // Update pagination metadata
        this.currentPage = data.message.currentPage;
        this.totalPages = data.message.totalPages;
        this.itemsPerPage = data.message.itemsPerPage;
        this.totalItems = data.message.totalItems;
      } else {
        this.error = "No templates found or invalid response format";
      }
    } catch (error) {
      console.error("Error loading templates:", error);
      this.error =
        error.body?.message ||
        error.message ||
        "Failed to load document templates";
      this.showToast("Error", this.error, "error");
    } finally {
      this.isLoading = false;
    }
  }

  handleRefresh() {
    this.loadTemplates(this.currentPage, this.itemsPerPage);
  }

  // Pagination methods
  handlePreviousPage() {
    if (this.currentPage > 0) {
      this.loadTemplates(this.currentPage - 1, this.itemsPerPage);
    }
  }

  handleNextPage() {
    if (this.currentPage < this.totalPages - 1) {
      this.loadTemplates(this.currentPage + 1, this.itemsPerPage);
    }
  }

  handleFirstPage() {
    if (this.currentPage > 0) {
      this.loadTemplates(0, this.itemsPerPage);
    }
  }

  handleLastPage() {
    if (this.currentPage < this.totalPages - 1) {
      this.loadTemplates(this.totalPages - 1, this.itemsPerPage);
    }
  }

  showToast(title, message, variant) {
    const event = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant
    });
    this.dispatchEvent(event);
  }

  get hasTemplates() {
    return this.templates && this.templates.length > 0;
  }

  get hasError() {
    return this.error && !this.isLoading;
  }

  // Pagination getters
  get hasPagination() {
    return this.totalPages > 1;
  }

  get canGoPrevious() {
    return this.currentPage > 0;
  }

  get canGoNext() {
    return this.currentPage < this.totalPages - 1;
  }

  get isPreviousDisabled() {
    return !this.canGoPrevious;
  }

  get isNextDisabled() {
    return !this.canGoNext;
  }

  get pageInfo() {
    if (this.totalItems === 0) return "No items";
    const start = this.currentPage * this.itemsPerPage + 1;
    const end = Math.min(
      (this.currentPage + 1) * this.itemsPerPage,
      this.totalItems
    );
    return `${start}-${end} of ${this.totalItems} items`;
  }

  get currentPageDisplay() {
    return this.currentPage + 1; // Display as 1-indexed
  }

  // Format type for display
  formatType(type) {
    const typeMap = {
      GENERAL: "General",
      SUITABILITY_LETTER: "Suitability Letter",
      TOP_UP_LETTER: "Top Up Letter"
    };
    return typeMap[type] || type;
  }

  // Handle row actions
  handleRowAction(event) {
    const actionName = event.detail.action.name;
    const row = event.detail.row;

    switch (actionName) {
      case "download":
        this.downloadTemplate(row.id, row.name);
        break;
      case "share":
        this.shareTemplate(row.id, row.name);
        break;
      case "unshare":
        this.unshareTemplate(row.id, row.name);
        break;
      case "delete":
        this.deleteTemplate(row.id, row.name);
        break;
      default:
        break;
    }
  }

  async downloadTemplate(templateId, templateName) {
    try {
      this.isLoading = true;
      const response = await getDocumentTemplate({ templateId });
      const data = JSON.parse(response);

      if (data.success && data.message && data.message.file) {
        const fileData = data.message.file;
        const base64Data = fileData.base64;
        const fileName = fileData.name || templateName;
        const mimeType = "application/zip";

        // Convert base64 to blob and trigger download
        const byteCharacters = atob(base64Data);
        const byteNumbers = new Array(byteCharacters.length);
        for (let i = 0; i < byteCharacters.length; i++) {
          byteNumbers[i] = byteCharacters.charCodeAt(i);
        }
        const byteArray = new Uint8Array(byteNumbers);
        const blob = new Blob([byteArray], { type: mimeType });

        // Create download link
        const url = window.URL.createObjectURL(blob);
        const link = document.createElement("a");
        link.href = url;
        link.download = fileName.endsWith(".docx")
          ? fileName
          : fileName + ".docx";
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        window.URL.revokeObjectURL(url);

        this.showToast(
          "Success",
          "Template downloaded successfully",
          "success"
        );
      } else {
        this.showToast(
          "Error",
          "Failed to download template: Invalid response format",
          "error"
        );
      }
    } catch (error) {
      console.error("Error downloading template:", error);
      const errorMessage =
        error.body?.message || error.message || "Failed to download template";
      this.showToast("Error", errorMessage, "error");
    } finally {
      this.isLoading = false;
    }
  }

  async shareTemplate(templateId, templateName) {
    try {
      const confirmed = await this.showConfirmDialog(
        "Share Template",
        `Are you sure you want to share the template "${templateName}" with your organization?`,
        "Share",
        "Cancel"
      );

      if (!confirmed) return;

      this.isLoading = true;
      const response = await toggleDocumentTemplateShare({ templateId });
      const data = JSON.parse(response);

      if (data.success) {
        this.showToast("Success", "Template shared successfully", "success");
        this.loadTemplates(this.currentPage, this.itemsPerPage);
      } else {
        this.showToast(
          "Error",
          "Failed to share template: " + (data.message || "Unknown error"),
          "error"
        );
      }
    } catch (error) {
      console.error("Error sharing template:", error);
      const errorMessage =
        error.body?.message || error.message || "Failed to share template";
      this.showToast("Error", errorMessage, "error");
    } finally {
      this.isLoading = false;
    }
  }

  async unshareTemplate(templateId, templateName) {
    try {
      const confirmed = await this.showConfirmDialog(
        "Unshare Template",
        `Are you sure you want to unshare the template "${templateName}" from your organization?`,
        "Unshare",
        "Cancel"
      );

      if (!confirmed) return;

      this.isLoading = true;
      const response = await toggleDocumentTemplateShare({ templateId });
      const data = JSON.parse(response);

      if (data.success) {
        this.showToast("Success", "Template unshared successfully", "success");
        this.loadTemplates(this.currentPage, this.itemsPerPage);
      } else {
        this.showToast(
          "Error",
          "Failed to unshare template: " + (data.message || "Unknown error"),
          "error"
        );
      }
    } catch (error) {
      console.error("Error unsharing template:", error);
      const errorMessage =
        error.body?.message || error.message || "Failed to unshare template";
      this.showToast("Error", errorMessage, "error");
    } finally {
      this.isLoading = false;
    }
  }

  async deleteTemplate(templateId, templateName) {
    // Show confirmation dialog
    const result = await this.showConfirmDialog(
      "Delete Template",
      `Are you sure you want to delete the template "${templateName}"? This action cannot be undone.`,
      "Delete",
      "Cancel"
    );

    if (!result) {
      return; // User cancelled
    }

    try {
      this.isLoading = true;
      const response = await deleteDocumentTemplate({ templateId });
      const data = JSON.parse(response);

      if (data.success) {
        this.showToast("Success", "Template deleted successfully", "success");

        // Refresh the templates list
        this.loadTemplates(this.currentPage, this.itemsPerPage);
      } else {
        this.showToast(
          "Error",
          "Failed to delete template: " + (data.message || "Unknown error"),
          "error"
        );
      }
    } catch (error) {
      console.error("Error deleting template:", error);
      const errorMessage =
        error.body?.message || error.message || "Failed to delete template";
      this.showToast("Error", errorMessage, "error");
    } finally {
      this.isLoading = false;
    }
  }

  // Show confirmation dialog using native browser confirm
  // Note: In a production environment, you might want to use a custom modal
  showConfirmDialog(title, message) {
    return new Promise((resolve) => {
      const confirmed = confirm(`${title}\n\n${message}`);
      resolve(confirmed);
    });
  }

  // Event handlers for connection status component
  handleConnectionStatusChange(event) {
    const { isConnected, isNotAllowed, statusChanged } = event.detail;
    this.isConnected = isConnected;
    this.isNotAllowed = isNotAllowed;

    if (statusChanged && isConnected) {
      // Load templates and user data when connection is established
      this.loadTemplates();
      this.loadUserData();
    } else if (!isConnected) {
      // Reset state when disconnected
      this.templates = [];
      this.userData = null;
      this.userHasOrganisation = false;
      this.isLoading = false;
      this.error = null;
    }
  }

  handleConnectionError(event) {
    const { error } = event.detail;
    this.showToast("Connection Error", this.getErrorMessage(error), "error");
    this.isLoading = false;
  }

  handleUserRegistered() {
    console.log("User successfully registered with Mirrexa");
    this.loadTemplates();
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