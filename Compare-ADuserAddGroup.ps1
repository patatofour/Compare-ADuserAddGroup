<#   
.SYNOPSIS   
	Script that compares group membership of source users and destination user and adds destination user to source user group 
    
.DESCRIPTION 
	This script compares the group membership of $sourceacc and $destacc, based on the membership of the source account
	the destination account is also to these groups. Script outputs actions taken to the prompt. The script can also be run
	without any parameters then the script will prompt for both usernames.
 
.PARAMETER Sourceacc
    User of which group membership is read

.PARAMETER Filename
    User that becomes member of all the groups that Sourceacc is member of
    
.PARAMETER Noconfirm
	No user input is required and the script runs automatically

.NOTES   
    Name: Compare-ADuserAddGroup.ps1
    Author: Jaap Brasser
    DateCreated: 14-03-2012
	.

.EXAMPLE   
	.\Compare-ADuserAddGroup.ps1 testuserabc123 testuserabc456

Description 
-----------     
This command will add testuserabc456 to all groups that testuserabc123 is a memberof with the exception of all
groups testuserabc456 is already a member of.

.EXAMPLE   
	.\Compare-ADuserAddGroup.ps1
#>
param(
	$sourceacc,
	$destacc,
	[switch]$noconfirm
)

# Checks if both accounts are provided as an argument, otherwise prompts for input
if (-not $sourceacc) { $sourceacc = read-host "Please input source user name, the user the rights will be read from" }
if (-not $destacc) { $destacc = read-host "Please input destination user name, the user which will be added to the groups of the source user" }

# Retrieves the group membership for both accounts
$sourcemember = get-aduser -filter {samaccountname -eq $sourceacc} -property memberof | select memberof
$destmember = get-aduser -filter {samaccountname -eq $destacc} -property memberof | select memberof

# Checks if accounts have group membership, if no group membership is found for either account script will exit
if ($sourcemember -eq $null) {"Source user not found";return}
if ($destmember -eq $null) {"Destination user not found";return}

# Checks for differences, if no differences are found script will prompt and exit
if (-not (compare-object $destmember.memberof $sourcemember.memberof | where-object {$_.sideindicator -eq '=>'})) {write-host "No difference between $sourceacc & $destacc groupmembership found. $destacc will not be added to any additional groups.";return}

# Routine that changes group membership and displays output to prompt
compare-object $destmember.memberof $sourcemember.memberof | where-object {$_.sideindicator -eq '=>'} |
	select -expand inputobject | foreach {write-host "$destacc will be added to:"([regex]::split($_,'^CN=|,OU=.+$'))[1]}

# If no confirmation parameter is set no confirmation is required, otherwise script will prompt for confirmation
if ($noconfirm)	{
	compare-object $destmember.memberof $sourcemember.memberof | where-object {$_.sideindicator -eq '=>'} | 
		select -expand inputobject | foreach {add-adgroupmember "$_" $destacc}
}

else {
	do{
	    $UserInput = Read-Host "Are you sure you wish to add $destacc to these groups?`n[Y]es, [N]o or e[X]it"
	    if (("Y","yes","n","no","X","exit") -notcontains $UserInput) {
	        $UserInput = $null
	        Write-Warning "Please input correct value"
	    }
	    if (("X","exit","N","no") -contains $UserInput) {
	        Write-Host "No changes made, exiting..."
	        exit
	    }     
	    if (("Y","yes") -contains $UserInput) {
	        compare-object $destmember.memberof $sourcemember.memberof | where-object {$_.sideindicator -eq '=>'} | 
				select -expand inputobject | foreach {add-adgroupmember "$_" $destacc}
	    }
	}
	until ($UserInput -ne $null)
}