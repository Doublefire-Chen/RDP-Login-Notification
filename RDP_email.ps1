[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$event = get-winevent -FilterHashtable @{Logname='Security';ID=4624} -MaxEvents 1


$connection=Get-NetTCPConnection | Where-Object { $_.LocalPort -eq 3389 -and $_.State -eq 'Established'} -OutVariable conn  
$remote_port= $conn.RemotePort
$ip=$conn.RemoteAddress
$hostname = $event.Properties[1].Value.TrimEnd('$')
$user = $event.Properties[5].Value
$datetime = $event.TimeCreated.ToString("dd.MMM.yyyy HH:mm:ss")


$env:NALI_DB_IP4="geoip"
$env:NALI_LANG="en"


$nali = & C:\Users\Developer\Desktop\nali.exe $ip
$from_region = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes($nali))

$from_region = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::UTF8.GetBytes($nali))
#Write-Output $from_region

# 构建包含消息的关联数组
$data = @{
    "hostname_1" = "$hostname"
    "user" = "$user"
    "server_time" = "$datetime"
    "from_ip" = "$ip"
    "from_port" = "$remote_port"
    "from_region" = "$from_region"

}

# 将关联数组转换为 JSON 格式
$jsonData = $data | ConvertTo-Json

#Write-Output $jsonData
#exit

# set your webhook url here
$webhookURL = 'https://example.com/prometheusalert?type=email&tpl=RDP-warning'

# 发送 HTTP POST 请求
Invoke-RestMethod -Uri $webhookURL -Method Post -Body $jsonData -ContentType 'application/json'


