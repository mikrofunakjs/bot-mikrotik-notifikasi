# =============================================================================
#  bot-startup — inisialisasi + notifikasi saat router reboot
# =============================================================================
#  Winbox: System → Scripts → Add (+)
#    Name: bot-startup
#    Policy: read, write, policy, test
#    Source: copy-paste isi file ini

/system script run bot-config
:global botToken
:global botChatId
:global botHotspotState [:toarray ""]
:global botPppoeState [:toarray ""]
:global botIfaceState [:toarray ""]

:local identity [/system identity get name]
:local version [/system resource get version]
:local clock [/system clock get time]
:local msg "\F0\9F\94\84 <b>Router Started</b>%0AName: $identity%0AVersion: $version%0ATime: $clock"
:local url "https://api.telegram.org/bot$botToken/sendMessage"
:local data "chat_id=$botChatId&text=$msg&parse_mode=HTML"
/tool fetch url="$url" http-method=post http-data="$data" mode=https keep-result=no
