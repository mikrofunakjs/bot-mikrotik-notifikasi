# =============================================================================
#  bot-startup — inisialisasi saat router reboot
# =============================================================================
#  Cara pakai:
#   Winbox → System → Scripts → Add (+)
#     Name: bot-startup
#     Policy: read, write, policy, test
#   Copy-paste isi di bawah ke kolom Source, OK.
# =============================================================================

/system script run bot-config
:global botSend
:global botHotspotState [:toarray ""]
:global botPppoeState [:toarray ""]
:global botIfaceState [:toarray ""]

:local identity [/system identity get name]
:local version [/system resource get version]
:local clock [/system clock get time]
:local msg "\F0\9F\94\84 <b>Router Started</b>%0AName: $identity%0AVersion: $version%0ATime: $clock"
$botSend $msg
