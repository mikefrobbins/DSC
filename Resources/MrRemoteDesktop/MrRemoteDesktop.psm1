enum Ensure {
    Absent
    Present
}
enum UserAuthenication {
    NonSecure
    Secure
}

[DscResource()]
class RemoteDesktop {

    [DscProperty(Key)]
    [UserAuthenication]$UserAuthenication

    [DscProperty(Mandatory)]
    [Ensure]$Ensure

    [RemoteDesktop]Get() {

        $this.UserAuthenication = $this.GetAuthSetting()
        $this.Ensure = $this.GetTSSetting()

	    Return $this

    }

    [void]Set(){

        if ($this.TestAuthSetting() -eq $false) {
            $this.SetAuthSetting($this.UserAuthenication)            
        }

        if ($this.TestTSSetting() -eq $false) {
            $this.SetTSSetting($this.Ensure)            
        }

    }

    [bool]Test(){

        if ($this.TestAuthSetting() -and $this.TestTSSetting() -eq $true) {
            Return $true
        }
        else {
            Return $false
        }

    }

    [string]GetAuthSetting(){
        
        $AuthCurrentSetting = Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name 'UserAuthentication' |
                              Select-Object -ExpandProperty UserAuthentication

        $AuthSetting = switch ($AuthCurrentSetting) {
            0 {'NonSecure'; Break}
            1 {'Secure'; Break}
        }

	    Return $AuthSetting

    }

    [string]GetTSSetting(){

        $TSCurrentSetting = Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' |
                            Select-Object -ExpandProperty fDenyTSConnections

        $TSSetting = switch ($TSCurrentSetting) {
            0 {'Present'; Break}
            1 {'Absent'; Break}
        }

	    Return $TSSetting

    }

    [void]SetAuthSetting([UserAuthenication]$UserAuthenication){

        switch ($this.UserAuthenication) {
            'NonSecure' {$Script:AuthDesiredSetting = 0; Break}
            'Secure' {$Script:AuthDesiredSetting = 1; Break}
        }

        Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name 'UserAuthentication' -Value $Script:AuthDesiredSetting

    }

    [void]SetTSSetting([Ensure]$Ensure){

        switch ($this.Ensure) {
            'Present' {$Script:TSDesiredSetting = 0; Break}
            'Absent' {$Script:TSDesiredSetting = 1; Break}
        }

        Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -Value $Script:TSDesiredSetting

    }

    [bool]TestAuthSetting(){

        if ($this.UserAuthenication -eq $this.GetAuthSetting()){
            Return $true
        }
        else {
            Return $false
        }

    }

    [bool]TestTSSetting(){

        if ($this.Ensure -eq $this.GetTSSetting()){
            Return $true
        }
        else {
            Return $false
        }

    }
    
}