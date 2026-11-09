#Requires -RunAsAdministrator
# Configura Oracle Client x86 + x64 lado a lado via link simbolico ora112.
# Faz backup em C:\Oracle\backup-config antes de alterar. Reversivel com os arquivos de backup.

$ErrorActionPreference = 'Stop'

$x64Home  = 'C:\Oracle\11.2\Client_x64\product\12.2.0\client_1'
$x86Home  = 'C:\Oracle\11.2\Client_x86\product\12.1.0\client_1'
$link     = 'C:\Windows\System32\ora112'
$tnsAdmin = 'C:\Oracle\Common\network\admin'
$backup   = 'C:\Oracle\backup-config'
$stamp    = Get-Date -Format 'yyyyMMdd-HHmmss'

# --- pre-checagens ---
foreach ($p in $x64Home, $x86Home, "$x64Home\oci.dll", "$x86Home\oci.dll") {
    if (-not (Test-Path $p)) { throw "Nao encontrado: $p" }
}
foreach ($l in @{ 'C:\Windows\System32\ora112' = $x64Home; 'C:\Windows\SysWOW64\ora112' = $x86Home }.GetEnumerator()) {
    $i = Get-Item $l.Key -Force -ErrorAction SilentlyContinue
    if (-not $i -or $i.LinkType -ne 'SymbolicLink' -or ($i.Target | Select-Object -First 1) -ne $l.Value) {
        throw "Link $($l.Key) ausente ou apontando para o lugar errado."
    }
}

# --- backup ---
New-Item -ItemType Directory -Force $backup | Out-Null
$envKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
(Get-ItemProperty $envKey).Path | Set-Content "$backup\PATH-machine-$stamp.txt" -Encoding utf8
reg export 'HKLM\SOFTWARE\ORACLE' "$backup\oracle-64-$stamp.reg" /y | Out-Null
reg export 'HKLM\SOFTWARE\Wow6432Node\ORACLE' "$backup\oracle-32-$stamp.reg" /y | Out-Null
Write-Host "Backup salvo em $backup"

# --- TNS_ADMIN comum (copia, nao move; originais ficam intactos) ---
New-Item -ItemType Directory -Force $tnsAdmin | Out-Null
foreach ($f in 'tnsnames.ora', 'sqlnet.ora') {
    $dest = Join-Path $tnsAdmin $f
    if (-not (Test-Path $dest)) { Copy-Item "$x64Home\Network\Admin\$f" $dest }
}
[Environment]::SetEnvironmentVariable('TNS_ADMIN', $tnsAdmin, 'Machine')

# --- ORACLE_HOME ---
[Environment]::SetEnvironmentVariable('ORACLE_HOME', $link, 'Machine')

# --- PATH: troca os caminhos diretos por ora112, mantendo a posicao ---
$old = (Get-Item $envKey).GetValue('Path', '', 'DoNotExpandEnvironmentNames') -split ';' | Where-Object { $_ }
$drop = @($x86Home, "$x86Home\bin", $x64Home, "$x64Home\bin") | ForEach-Object { $_.TrimEnd('\').ToLower() }
$new = New-Object System.Collections.Generic.List[string]
$inserted = $false
foreach ($e in $old) {
    if ($drop -contains $e.TrimEnd('\').ToLower()) {
        if (-not $inserted) { $new.Add($link); $new.Add("$link\bin"); $inserted = $true }
        continue
    }
    if ($e.ToLower() -like 'c:\windows\syswow64\ora112*') { continue }  # nunca no PATH
    $new.Add($e)
}
if (-not $inserted) { $new.Insert(0, "$link\bin"); $new.Insert(0, $link) }
$dedup = $new | Select-Object -Unique
Set-ItemProperty $envKey -Name Path -Value ($dedup -join ';') -Type ExpandString

# --- Registro: ORACLE_HOME (conforme o roteiro: ambos apontam para System32\ora112) ---
Set-ItemProperty 'HKLM:\SOFTWARE\ORACLE\KEY_OraClient12Home1' -Name ORACLE_HOME -Value $link
Set-ItemProperty 'HKLM:\SOFTWARE\Wow6432Node\ORACLE\KEY_OraClient12Home1_32bit' -Name ORACLE_HOME -Value $link
Set-ItemProperty 'HKLM:\SOFTWARE\ORACLE\KEY_OraClient12Home1' -Name TNS_ADMIN -Value $tnsAdmin
Set-ItemProperty 'HKLM:\SOFTWARE\Wow6432Node\ORACLE\KEY_OraClient12Home1_32bit' -Name TNS_ADMIN -Value $tnsAdmin

# --- avisa os processos abertos da mudanca de ambiente ---
Add-Type -Namespace Win32 -Name Native -MemberDefinition '[DllImport("user32.dll", SetLastError=true, CharSet=CharSet.Auto)] public static extern IntPtr SendMessageTimeout(IntPtr h, uint m, UIntPtr w, string l, uint f, uint t, out UIntPtr r);'
$r = [UIntPtr]::Zero
[Win32.Native]::SendMessageTimeout([IntPtr]0xffff, 0x1A, [UIntPtr]::Zero, 'Environment', 2, 5000, [ref]$r) | Out-Null

Write-Host "`nConcluido. Feche e reabra terminais/IDEs/apps para pegar o novo ambiente."
