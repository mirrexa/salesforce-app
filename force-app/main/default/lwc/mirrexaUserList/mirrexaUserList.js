import { LightningElement, track, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getUsersWithMirrexaAccess from "@salesforce/apex/MirrexaAdminController.getUsersWithMirrexaAccess";
import removeMirrexaAccessFromUsers from "@salesforce/apex/MirrexaAdminController.removeMirrexaAccessFromUsers";

export default class MirrexaUserList extends LightningElement {
  @track users = [];
  @track selectedUserIds = [];
  @track isLoading = false;

  @wire(getUsersWithMirrexaAccess)
  wiredUsers(result) {
    this.wiredUsersResult = result;
    if (result.data) {
      // Format user data for card display
      this.users = result.data.map((user) => ({
        ...user,
        emailLink: `mailto:${user.email}`,
        activeLabel: user.isActive ? "Active" : "Inactive",
        activeVariant: user.isActive ? "success" : "error",
        assignedDateFormatted: user.assignedDate
          ? new Date(user.assignedDate).toLocaleDateString()
          : "N/A"
      }));
    } else if (result.error) {
      this.showToast(
        "Error",
        "Failed to load users: " + result.error.body?.message,
        "error"
      );
    }
  }

  handleCardSelection(event) {
    const userId = event.target.dataset.userId;
    const isChecked = event.target.checked;

    if (isChecked) {
      if (!this.selectedUserIds.includes(userId)) {
        this.selectedUserIds = [...this.selectedUserIds, userId];
      }
    } else {
      this.selectedUserIds = this.selectedUserIds.filter((id) => id !== userId);
    }
  }

  handleCardAction(event) {
    const actionName = event.detail.value;
    const userId = event.target.dataset.userId;
    const userName = event.target.dataset.userName;

    if (actionName === "remove_access") {
      this.removeAccessFromUser(userId, userName);
    }
  }

  async removeAccessFromUser(userId, userName) {
    try {
      this.isLoading = true;
      const result = await removeMirrexaAccessFromUsers([userId]);

      if (result.success) {
        this.showToast(
          "Success",
          `Mirrexa access removed from ${userName}`,
          "success"
        );
        await refreshApex(this.wiredUsersResult);
      } else {
        this.showToast(
          "Error",
          result.error || "Failed to remove access",
          "error"
        );
      }
    } catch (error) {
      this.showToast(
        "Error",
        "Failed to remove access: " + error.body?.message,
        "error"
      );
    } finally {
      this.isLoading = false;
    }
  }

  async handleBulkRemove() {
    if (this.selectedUserIds.length === 0) {
      this.showToast(
        "Warning",
        "Please select users to remove access from",
        "warning"
      );
      return;
    }

    try {
      this.isLoading = true;
      const result = await removeMirrexaAccessFromUsers(this.selectedUserIds);

      if (result.success) {
        this.showToast(
          "Success",
          `Mirrexa access removed from ${result.removedCount} user(s)`,
          "success"
        );
        await refreshApex(this.wiredUsersResult);
        this.selectedUserIds = [];
      } else {
        this.showToast(
          "Error",
          result.error || "Failed to remove access",
          "error"
        );
      }
    } catch (error) {
      this.showToast(
        "Error",
        "Failed to remove access: " + error.body?.message,
        "error"
      );
    } finally {
      this.isLoading = false;
    }
  }

  handleRefresh() {
    refreshApex(this.wiredUsersResult);
  }

  showToast(title, message, variant) {
    this.dispatchEvent(
      new ShowToastEvent({
        title,
        message,
        variant
      })
    );
  }

  get hasUsers() {
    return this.users && this.users.length > 0;
  }

  get hasSelectedUsers() {
    return this.selectedUserIds.length > 0;
  }

  get userCount() {
    return this.users ? this.users.length : 0;
  }
}