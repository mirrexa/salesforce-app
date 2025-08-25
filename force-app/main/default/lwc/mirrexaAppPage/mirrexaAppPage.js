import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { LightningElement, track } from "lwc";
import getSubscriptions from "@salesforce/apex/MirrexaApiService.getSubscriptions";

export default class MirrexaAppPage extends LightningElement {
  @track isConnected = false;
  @track isNotAllowed = false;
  @track isLoading = false;
  @track subscriptions = [];
  @track subscriptionsLoading = false;
  @track subscriptionsError = null;

  connectedCallback() {
    this.isLoading = true;
  }

  /**
   * Handle connection status change from mirrexaConnectionStatus component
   */
  handleConnectionStatusChange(event) {
    const { isConnected, isNotAllowed, statusChanged } = event.detail;

    this.isConnected = isConnected;
    this.isNotAllowed = isNotAllowed;
    this.isLoading = false;

    if (statusChanged) {
      if (isConnected) {
        this.showToast(
          "Success",
          "Successfully connected to Mirrexa",
          "success"
        );
        // Load subscriptions when connected
        this.loadSubscriptions();
      } else {
        this.showToast("Disconnected", "Connection to Mirrexa lost", "warning");
        // Clear subscriptions when disconnected
        this.subscriptions = [];
        this.subscriptionsError = null;
      }
    } else if (isConnected) {
      // Load subscriptions if already connected on component load
      this.loadSubscriptions();
    }
  }

  /**
   * Handle connection error from mirrexaConnectionStatus component
   */
  handleConnectionError(event) {
    const { error } = event.detail;
    this.showToast(
      "Connection Error",
      `Failed to check Mirrexa connection: ${error.body?.message || error.message}`,
      "error"
    );
  }

  /**
   * Handle user registration success from mirrexaConnectionStatus component
   */
  handleUserRegistered() {
    console.log("User successfully registered with Mirrexa");
  }

  /**
   * Load subscription data from Mirrexa API
   */
  async loadSubscriptions() {
    this.subscriptionsLoading = true;
    this.subscriptionsError = null;

    try {
      const response = await getSubscriptions();
      const data = JSON.parse(response);

      if (data.success && Array.isArray(data.message)) {
        this.subscriptions = data.message.map((sub) => ({
          ...sub,
          productTypeLabel: this.getProductTypeLabel(sub.product_type),
          productSubTypeLabel: this.getProductSubTypeLabel(
            sub.product_sub_type
          ),
          isActive: sub.is_active === 1,
          usagePercentage:
            sub.product_type_period_limit > 0
              ? Math.round(
                  (sub.product_type_usage_count /
                    sub.product_type_period_limit) *
                    100
                )
              : 0,
          formattedStartDate: this.formatDate(sub.start_date),
          formattedEndDate: this.formatDate(sub.end_date)
        }));
      } else {
        this.subscriptionsError =
          "Invalid response format from subscription API";
      }
    } catch (error) {
      console.error("Error loading subscriptions:", error);
      this.subscriptionsError =
        error.body?.message ||
        error.message ||
        "Failed to load subscription data";
    } finally {
      this.subscriptionsLoading = false;
    }
  }

  /**
   * Get human-readable label for product type
   */
  getProductTypeLabel(productType) {
    const labels = {
      "ai-documents": "AI Documents",
      "suitability-letter": "Suitability Letter",
      "top-up-letter": "Top-up Letter",
      "client-income-report": "Client Income Report"
    };
    return labels[productType] || productType;
  }

  /**
   * Get human-readable label for product sub type
   */
  getProductSubTypeLabel(productSubType) {
    const labels = {
      trial: "Trial",
      basic: "Basic",
      pro: "Pro"
    };
    return labels[productSubType] || productSubType;
  }

  /**
   * Format date string for display
   */
  formatDate(dateString) {
    if (!dateString) return "";
    try {
      return new Date(dateString).toLocaleDateString();
    } catch (error) {
      return dateString;
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
}