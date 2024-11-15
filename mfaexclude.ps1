function Validate-RunAs {
    # Set group membership requirements, these groups validate whether the user can execute the commands used later
    $requiredGroups = @(
        "Corp Domain Admin Group",
        "Corp Super User Admin Group"
    )

    # get credentials and validate format
    $runningCredentials = Get-Credential -Message "Enter your full Principal Name for your admin account (e.g., ad_admin@company.com)"
    $credName = $runningCredentials.UserName
    if ($credName -notlike "*@companydomain") {
        Write-Error "Please use your full userPrincipalName - e.g., ad_admin@wcompany.com"
        return $null
    }

    # Retrieve AD user info, pull attribute9 for later, default $isElevated to $false
    $credInfo = Get-ADUser -Filter { UserPrincipalName -eq $credName } -Properties memberof, extensionAttribute9
    $isElevated = $false
    $credEmail = $credInfo.extensionAttribute9

    # Check for required group membership, validate against $requiredgroups
    if ($credInfo.memberof | ForEach-Object { $requiredGroups -contains $_ }) {
        Write-Host "This account has elevated privileges." -ForegroundColor Green
        $isElevated = $true
    }
    else {
        Write-Error "This account lacks the required access."
    }

    # Return results for checks as a custom object
    [PSCustomObject]@{
        RunAsName  = $credName
        RunAsEmail = $credEmail
        IsElevated = $isElevated
    }
}

function Find-ValidADUser {
    param (
        [string]$userInput
    )

    # Process and clean the input user list, using split to remove commas and trimming extra spaces, cleaning out empty entries, verifying no unaccepted characters in the list of users (not necassary, but safe)
    $userList = $userInput.Split(",") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
    $validatedUsers = @()

    foreach ($user in $userList) {
        if ($user -notmatch "^[a-zA-Z0-9._']+$") {
            Write-Host "Invalid Username: $user, please correct and try again."
        }
        else {
            # Verify AD user exists
            $adUser = Get-ADUser -Filter { SamAccountName -eq $user } -ErrorAction SilentlyContinue
            $userInAD = $null -ne $adUser

            # Create custom object for each user
            $validatedUsers += [PSCustomObject]@{
                Username  = $user
                IsValid   = $userInAD
            }

            if (-not $userInAD) {
                Write-Host "User not found in AD: $user" -ForegroundColor Yellow
            }
        }
    }

    # Return list of valid AD users only
    return $validatedUsers | Where-Object { $_.IsValid -eq $true }
}

function AddUser-MFAExclude {
    param (
        [array]$validatedUserList,
        [string]$adminCred,
        [string]$adminEmail
)

    $usersAdded = @()
    $dateTime = Get-Date
    $shortDate = $dateTime.ToString("MM-dd-yyyy")
    $timeAdded = $dateTime.ToString("hh:mm")

    foreach ($user in $validatedUserList) {
        $userobj = [PSCustomObject]@{
            Username  = $user.Username
            DateAdded = $shortDate
            TimeAdded = $timeAdded
            AddedBy   = $adminCred
            AdminEmail = $adminEmail
        }

        # Add user to the MFA exclusion group (uncomment for production)
        # Add-ADGroupMember -Identity "MFA-Exclude" -Members $user.Username
        Write-Host "Add-ADGroupMember -Identity 'MFA-Exclude' -Members $($user.Username)" -ForegroundColor Green  # Testing output
        
        $usersAdded += $userobj
    }

    # Return list of added users
    return $usersAdded
}

# Start Script Logic

# Validate RunAs credentials
$adminInfo = Validate-RunAs
if (-not $adminInfo.IsElevated) {
    Write-Host "Insufficient permissions. Exiting script." -ForegroundColor Red
    return
}

$adminCred = ($adminInfo.RunAsName -split '@')[0]
$adminEmail = $adminInfo.RunAsEmail

# User validation loop
do {
    $userInput = Read-Host -Prompt "Enter Usernames you would like to modify, separated by commas"
    $validatedUserList = Find-ValidADUser -userInput $userInput

    if (-not $validatedUserList) {
        Write-Host "No valid users found or some users are missing in AD. Please re-enter." -ForegroundColor Yellow
    }
} while (-not $validatedUserList)

# Add users to MFA Exclusion Group
$usersAdded = AddUser-MFAExclude -validatedUserList $validatedUserList -adminCred $adminCred -adminEmail $adminEmail
Write-Host "Users successfully added to MFA Exclusion Group:" -ForegroundColor Green
$usersAdded | Format-Table -AutoSize
