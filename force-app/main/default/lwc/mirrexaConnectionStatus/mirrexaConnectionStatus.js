import autoRegisterUser from "@salesforce/apex/MirrexaApiService.autoRegisterUser";
import getAuthURL from "@salesforce/apex/MirrexaApiService.getAuthURL";
import isUserConnected from "@salesforce/apex/MirrexaApiService.isUserConnected";
import { LightningElement, api } from "lwc";

/**
 * Reusable component for managing Mirrexa connection status
 * Provides connection detection, auto-registration, and LWC-to-LWC communication
 */
export default class MirrexaConnectionStatus extends LightningElement {
  // Public properties for parent components to access
  @api canCheck = false;
  @api isConnected = false;
  @api isNotAllowed = false;
  @api isLoading = false;
  @api error = undefined;
  @api authUrl = undefined;

  async connectedCallback() {
    await this.refreshConnectionStatus();
  }

  /**
   * Public method to refresh connection status
   * Can be called by parent components
   */
  @api
  async refreshConnectionStatus() {
    this.isLoading = true;
    this.error = undefined;

    try {
      const connectionStatus = await isUserConnected();
      this.canCheck = true;
      await this.dispatchConnectionStatusEvent(false);
      const wasConnected = this.isConnected;

      this.isConnected = connectionStatus === "Connected";
      this.isNotAllowed =
        connectionStatus ===
        "The principalType parameter value doesn't exist or you may not have permission to access it.";

      // Handle auto-registration if newly connected
      if (this.isConnected) {
        await this.handleAutoRegistration();
      }

      // Dispatch connection status change event
      this.dispatchConnectionStatusEvent(wasConnected);
    } catch (error) {
      this.error = error;
      console.error("Error checking Mirrexa connection status:", error);

      await this.dispatchConnectionStatusEvent(false);
      // Dispatch error event
      this.dispatchEvent(
        new CustomEvent("connectionerror", {
          detail: { error: error }
        })
      );
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * Public method to get authentication URL
   * Can be called by parent components
   */
  @api
  async getAuthenticationUrl() {
    try {
      this.authUrl = await getAuthURL();
      return this.authUrl;
    } catch (error) {
      console.error("Error getting auth URL:", error);
      throw error;
    }
  }

  /**
   * Handle auto-registration with Mirrexa
   */
  async handleAutoRegistration() {
    try {
      await autoRegisterUser();

      // Dispatch registration success event
      this.dispatchEvent(
        new CustomEvent("userregistered", {
          detail: { success: true }
        })
      );
    } catch (error) {
      console.error("Error confirming user registration with Mirrexa:", error);

      // Dispatch registration error event (non-blocking)
      this.dispatchEvent(
        new CustomEvent("registrationerror", {
          detail: { error: error }
        })
      );
    }
  }

  /**
   * Dispatch connection status change event
   */
  dispatchConnectionStatusEvent(wasConnected) {
    const eventDetail = {
      isConnected: this.isConnected,
      isNotAllowed: this.isNotAllowed,
      wasConnected: wasConnected,
      statusChanged: wasConnected !== this.isConnected,
      canCheck: this.canCheck
    };

    // Dispatch general status change event
    this.dispatchEvent(
      new CustomEvent("connectionstatuschange", {
        detail: eventDetail
      })
    );

    // Dispatch specific events for easier handling
    if (this.isConnected && !wasConnected) {
      this.dispatchEvent(
        new CustomEvent("connected", {
          detail: eventDetail
        })
      );
    } else if (!this.isConnected && wasConnected) {
      this.dispatchEvent(
        new CustomEvent("disconnected", {
          detail: eventDetail
        })
      );
    }
  }

  /**
   * Handle connect button click (if using template)
   */
  async handleConnect() {
    try {
      const authUrl = await this.getAuthenticationUrl();
      window.open(authUrl, "_blank");
    } catch (error) {
      console.error("Error opening auth URL:", error);
    }
  }

  // Getters for template use
  get connectionStatusText() {
    if (this.isLoading) {
      return "Checking connection...";
    }
    if (this.isConnected) {
      return "Connected to Mirrexa";
    }
    if (this.isNotAllowed) {
      return "Permission denied";
    }
    return "Not connected to Mirrexa";
  }

  get showConnectButton() {
    return !this.isConnected && !this.isNotAllowed && !this.isLoading;
  }
}
