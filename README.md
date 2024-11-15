# MFAExclude.PS1 README

## Overview
This PowerShell script is designed to facilitate managing users in Active Directory (AD) and specifically adding users to the "MFA-Exclude" group. The script ensures secure execution by validating the credentials of the executing user and their group memberships. It also validates input user accounts before proceeding with any modifications.

---

## Features
- **RunAs Validation:** Ensures the script is executed by an authorized administrator with required AD group memberships.
- **User Validation:** Verifies that input usernames are valid and exist in Active Directory.
- **MFA Exclusion Management:** Adds valid users to the "MFA-Exclude" group while logging metadata like date, time, and executing admin details.
- **Custom Logging:** Outputs details of the changes for transparency and tracking.

---

## Prerequisites
- **PowerShell Version:** Ensure the script is run in an environment with PowerShell 5.1 or newer.
- **Active Directory Module:** The `Active Directory` PowerShell module must be installed and imported.
- **Administrative Permissions:** The executing user must belong to at least one of two security groups that define their access level witin the org
- **Network Connectivity:** Access to the domain controller for querying and modifying Active Directory.

---

## Usage Instructions

### Step 1: RunAs Validation
1. The script prompts for administrator credentials.
2. The provided credentials are checked for:
   - Valid format (e.g., `ad_admin@company.com`). - Add specific domainname for org
   - Membership in the required AD groups.
   - Script collects custom data from Attribute 9, containing the email address tied to the owner of the admin account.

If the credentials fail validation, the script terminates.

### Step 2: User Validation
1. Enter a comma-separated list of usernames when prompted.
2. The script validates each username by:
   - Cleaning and standardizing input based on known org standards
   - Checking for invalid characters.
   - Verifying the user exists in Active Directory.

Any invalid or non-existent usernames are flagged.

### Step 3: Add Users to MFA-Exclude AD Group
1. Once the users are validated, they are added to the `MFA-Exclude` group.
2. For each user, the script logs:
   - Username
   - Date and time of addition
   - Executing admin details (username and email)

The script outputs the results in a formatted table.

---

### Future Addtions:
1. Automate sending a notification email on a timer, this will inform the users running the script that they need to remove users from group
2. Improve logging
3. Modify for use with Powershell Universal for further automation
