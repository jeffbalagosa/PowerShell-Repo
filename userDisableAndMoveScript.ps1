# Use this script to disable, remove group memberships, and move a single User to your Disabled User Accounts OU Container

#figure out what server
#set domain values accordingly
$validAnswer = $false
While (-not $validAnswer) {
  $corpOrSvc = Read-Host "`nAre you modifying on domain1 or domain2"
  Switch ($corpOrSvc.ToLower()) {
    "<domain1>" {
      $validAnswer = $true
      #specify dc
      $domainController = '<serverName>'
      # Specify target OU. 
      $TargetOU = "<DN of OU you want to look into>" 
      #issue domain warning
      Write-Warning "Please ensure you opened this PowerShell window as your domain1 Admin.  Reopen as domain1 Admin if you didn't or aren't sure."
      $domain = 'corp'
    }
    "<domain2>" {
      $validAnswer = $true
      #specify dc
      $domainController = '<serverName>'
      # Specify target OU.
      $TargetOU = "<DN of OU you want to look into>" 
      #issue domain warning
      Write-Warning "Please ensure you opened this PowerShell window as your domain2 Admin.  Reopen as domain2 Admin if you didn't or aren't sure."
      $domain = 'svc'
    }
    Default { Write-Host "`nTry entering '<domain1>' or '<domain2>'." }
  }
}

#Specify user
$DistinguishedName = Read-Host "`nPlease enter the user's DN"

#get samAccountName from DN
$LoginName = Get-ADUser -server $domainController -Identity $DistinguishedName | Select-Object -ExpandProperty SamAccountName 

# prompt for path to save csv file, remove trailing slash if present, remove single and double quotes if present, and create directory if it doesn't exist
$CSVPath = Read-Host "`nPlease enter the path to the folder where you want to save the CSV file."
$CSVPath = $CSVPath.TrimEnd("\")
$CSVPath = $CSVPath -replace "'",""
$CSVPath = $CSVPath -replace '"',""
New-Item -ItemType "directory" -Path $CSVPath -ErrorAction SilentlyContinue

# exportCSV to desired location
Get-AdPrincipalGroupMembership -server $domainController -Identity $DistinguishedName | Select-Object Name | Export-Csv -Path "$CSVPath\$LoginName\$domain\GroupMemberships.csv" -NoTypeInformation
   
#disable the account
Disable-ADAccount -server $domainController -Identity $DistinguishedName -Confirm:$false

#remove all groups except domain users group
Get-AdPrincipalGroupMembership -server $domainController -Identity $DistinguishedName | Where-Object -Property Name -Ne -Value 'Domain Users' | Remove-AdGroupMember -Members $DistinguishedName -Confirm:$false

# Move user to target OU. 
Move-ADObject -server $domainController -Identity $DistinguishedName -TargetPath $TargetOU -Confirm:$false