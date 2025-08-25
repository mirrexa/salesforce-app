import { LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import searchPermissionSets from "@salesforce/apex/MirrexaAdminController.searchPermissionSets";
import getUsersInPermissionSet from "@salesforce/apex/MirrexaAdminController.getUsersInPermissionSet";
import assignMirrexaAccessToUsers from "@salesforce/apex/MirrexaAdminController.assignMirrexaAccessToUsers";

export default class MirrexaPermissionAssignment extends LightningElement {
  @track searchTerm = "";
  @track permissionSets = [];
  @track selectedPermissionSet = null;
  @track usersInPermissionSet = [];
  @track selectedUserIds = [];
  @track isLoading = false;
  @track isSearching = false;
  @track isAssigning = false;

  handleSearchTermChange(event) {
    this.searchTerm = event.target.value;
  }

  async handleSearchPermissionSets() {
    if (!this.searchTerm || this.searchTerm.trim().length < 2) {
      this.showToast(
        "Warning",
        "Please enter at least 2 characters to search",
        "warning"
      );
      return;
    }

    try {
      this.isSearching = true;
      this.permissionSets = await searchPermissionSets({
        searchTerm: this.searchTerm.trim()
      });

      if (this.permissionSets.length === 0) {
        this.showToast(
          "Info",
          "No permission sets found matching your search",
          "info"
        );
      }
    } catch (error) {
      this.showToast(
        "Error",
        "Failed to search permission sets: " + error.body?.message,
        "error"
      );
    } finally {
      this.isSearching = false;
    }
  }

  async handlePermissionSetSelect(event) {
    const permSetId = event.target.dataset.id;
    const permSet = this.permissionSets.find((ps) => ps.id === permSetId);

    if (permSet) {
      this.selectedPermissionSet = permSet;
      await this.loadUsersInPermissionSet(permSetId);
    }
  }

  async loadUsersInPermissionSet(permSetId) {
    try {
      this.isLoading = true;
      const users = await getUsersInPermissionSet({
        permissionSetId: permSetId
      });

      // Format user data for card display
      this.usersInPermissionSet = users.map((user) => ({
        ...user,
        emailLink: `mailto:${user.email}`,
        activeLabel: user.isActive ? "Active" : "Inactive",
        activeVariant: user.isActive ? "success" : "error"
      }));

      this.selectedUserIds = []; // Reset selection
    } catch (error) {
      this.showToast(
        "Error",
        "Failed to load users: " + error.body?.message,
        "error"
      );
    } finally {
      this.isLoading = false;
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

  async handleAssignMirrexaAccess() {
    if (this.selectedUserIds.length === 0) {
      this.showToast(
        "Warning",
        "Please select users to assign Mirrexa access to",
        "warning"
      );
      return;
    }

    try {
      this.isAssigning = true;
      const result = await assignMirrexaAccessToUsers({
        sourcePermissionSetId: this.selectedPermissionSet.id,
        userIds: this.selectedUserIds
      });

      if (result.success) {
        let message = `Successfully processed ${result.totalProcessed} user(s). `;
        message += `New assignments: ${result.newAssignments}, `;
        message += `Already had access: ${result.existingAssignments}`;

        if (result.failedAssignments && result.failedAssignments.length > 0) {
          message += `. Failed: ${result.failedAssignments.length}`;
        }

        this.showToast("Success", message, "success");
        this.selectedUserIds = []; // Reset selection

        // Refresh the user list to show updated status
        await this.loadUsersInPermissionSet(this.selectedPermissionSet.id);
      } else {
        this.showToast(
          "Error",
          result.error || "Failed to assign access",
          "error"
        );
      }
    } catch (error) {
      this.showToast(
        "Error",
        "Failed to assign access: " + error.body?.message,
        "error"
      );
    } finally {
      this.isAssigning = false;
    }
  }

  handleSelectAll() {
    this.selectedUserIds = this.usersInPermissionSet.map((user) => user.userId);

    // Update all card checkboxes
    const checkboxes = this.template.querySelectorAll(
      ".user-checkbox lightning-input"
    );
    checkboxes.forEach((checkbox) => {
      checkbox.checked = true;
    });
  }

  handleClearSelection() {
    this.selectedUserIds = [];

    // Clear all card checkboxes
    const checkboxes = this.template.querySelectorAll(
      ".user-checkbox lightning-input"
    );
    checkboxes.forEach((checkbox) => {
      checkbox.checked = false;
    });
  }

  handleClearSearch() {
    this.searchTerm = "";
    this.permissionSets = [];
    this.selectedPermissionSet = null;
    this.usersInPermissionSet = [];
    this.selectedUserIds = [];
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

  get hasPermissionSets() {
    return this.permissionSets && this.permissionSets.length > 0;
  }

  get hasSelectedPermissionSet() {
    return this.selectedPermissionSet !== null;
  }

  get hasUsersInPermissionSet() {
    return this.usersInPermissionSet && this.usersInPermissionSet.length > 0;
  }

  get hasSelectedUsers() {
    return this.selectedUserIds.length > 0;
  }

  get selectedUserCount() {
    return this.selectedUserIds.length;
  }

  get totalUserCount() {
    return this.usersInPermissionSet ? this.usersInPermissionSet.length : 0;
  }

  get isSearchDisabled() {
    return (
      this.isSearching || !this.searchTerm || this.searchTerm.trim().length < 2
    );
  }
}