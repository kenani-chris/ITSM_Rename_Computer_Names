function Main(){
	$computers = Import-Csv ComputerNames.csv -Header OldName, Company, Number, Location;
	$Credential = Get-Credential;

	Foreach ($Computer in $computers) 
	{
		$ComputerName = $Computer.OldName.Trim()
		if(ComputerIsReachable($ComputerName) -eq $true){
			$ComputerType = ComputerIsLaptopOrDesktop($ComputerName);
			$NewComputerName = $Computer.Company + $ComputerType + $Computer.Number;
			$NewComputerName = [string]$NewComputerName.Trim();
			$NewComputerDescription = $NewComputerName + "-" + $Computer.Location;
			
			try{
				$RemotePc = Get-WmiObject -class Win32_OperatingSystem -computername $ComputerName;
				$RemotePc.Description = $NewComputerDescription;
				$RemotePc.Put();
				Rename-Computer -ComputerName $ComputerName -NewName $NewComputerName -DomainCredential $Credential -force;
				echo $ComputerName >> C:\computers\success.txt;
			}
			catch{
				echo $ComputerName >> C:\computers\not_renamed.txt
				echo $_ >> C:\computers\not_renamed.txt
				echo $_.ScriptStackTrace >> C:\computers\not_renamed.txt
			}
		}
	}
}


function ComputerIsReachable{
	param(
		$ComputerName
	)
	
	IF (Test-Connection -BufferSize 32 -Count 1 -ComputerName $ComputerName -Quiet) {
		return $true
	} Else {
		echo $ComputerName >> C:\computers\not_reachable.txt;
		return $false
	}
}


function Get-ComputerIsLaptopOrDesktop{
	param(
		$ComputerName
	)
	try{
		$ChasisType = wmic systemenclosure get chassistypes
		$ChasisType = $ChasisType.replace(' ', '');
		$ChasisType = $ChasisType.Trim("ChasisTypes").Trim("{").Trim("}") | Out-String
		$ChasisType = [int]$ChasisType.Replace("`n", "")

		if(($ChasisType -eq 13) -or ($ChasisType -le 7))
		{
			echo $ComputerName >> C:\computers\DSK.txt
			return "DSK"
		}else{
			echo $ComputerName >> C:\computers\LPT.txt
			return "LPT"
		}

	}
	catch{
		echo $ComputerName >> C:\computers\not_identified.txt
	}
}

