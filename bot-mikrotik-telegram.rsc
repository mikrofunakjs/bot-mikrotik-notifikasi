# =============================================================================
#  Bot Notifikasi MikroTik → Telegram  v2.0
#  =============================================================================
#  Repo: https://github.com/mikrofunakjs/bot-mikrotik-notifikasi
#  =============================================================================
#  CARA PAKAI:
#    Metode A (Import): Upload file → /import file=bot-mikrotik-telegram.rsc
#    Metode B (Winbox GUI): System → Scripts → Add, copy isi dari folder scripts/
#  =============================================================================

# =============================================================================
#  [1/5] KONFIGURASI — WAJIB DIGANTI
# =============================================================================
/system script remove [find name="bot-config"]
/system script add name="bot-config" owner="admin" policy=read,write,policy,test source={
##### GANTI DI BAWAH INI #####
:global botToken "123456:ABC-DEF1234ghijklmnop"
:global botChatId "123456789"
##### STOP GANTI #############
}

# =============================================================================
#  [2/5] MONITOR: bot-hotspot-mon — voucher login/logout
#  Inline /tool fetch — tidak pakai fungsi, tidak cross-script call.
# =============================================================================
/system script remove [find name="bot-hotspot-mon"]
/system script add name="bot-hotspot-mon" owner="admin" policy=read,write,policy,test source={
:global botToken
:global botChatId
:global botHotspotState
:if ([:typeof $botHotspotState] != "array") do={ :global botHotspotState [:toarray ""] }

:local activeUsers [/ip hotspot active find]
:local currentState [:toarray ""]

:foreach id in=$activeUsers do={
    :local user [/ip hotspot active get $id user]
    :local uptime [/ip hotspot active get $id uptime]
    :local server [/ip hotspot active get $id server]
    :local address [/ip hotspot active get $id address]
    :local mac [/ip hotspot active get $id mac-address]
    :local info "$uptime|$server|$address|$mac"
    :set ($currentState->$user) $info

    :if ([:typeof ($botHotspotState->$user)] = "nothing") do={
        :local msg "\F0\9F\9F\A2 <b>Hotspot Login</b>%0AUser: $user%0AServer: $server%0AIP: $address%0AMAC: $mac"
        :local url "https://api.telegram.org/bot$botToken/sendMessage"
        :local data "chat_id=$botChatId&text=$msg&parse_mode=HTML"
        /tool fetch url="$url" http-method=post http-data="$data" mode=https keep-result=no
    }
}

:foreach user,data in=$botHotspotState do={
    :if ([:typeof ($currentState->$user)] = "nothing") do={
        :local partsLen [:len $data]
        :local p1 [:find $data "|" 0]
        :if ($p1 < $partsLen) do={
            :local rest1 [:pick $data ($p1 + 1) $partsLen]
            :local p2 [:find $rest1 "|" 0]
            :if ($p2 >= 0) do={
                :local address [:pick $rest1 0 $p2]
                :local rest2 [:pick $rest1 ($p2 + 1) [:len $rest1]]
                :local mac $rest2
                :local msg "\F0\9F\94\B4 <b>Hotspot Logout</b>%0AUser: $user%0AIP: $address%0AMAC: $mac"
                :local url "https://api.telegram.org/bot$botToken/sendMessage"
                :local data "chat_id=$botChatId&text=$msg&parse_mode=HTML"
                /tool fetch url="$url" http-method=post http-data="$data" mode=https keep-result=no
            }
        }
    }
}

:global botHotspotState $currentState
}

# =============================================================================
#  [3/5] MONITOR: bot-pppoe-mon — PPPoE connect/disconnect
# =============================================================================
/system script remove [find name="bot-pppoe-mon"]
/system script add name="bot-pppoe-mon" owner="admin" policy=read,write,policy,test source={
:global botToken
:global botChatId
:global botPppoeState
:if ([:typeof $botPppoeState] != "array") do={ :global botPppoeState [:toarray ""] }

:local activePPPoE [/ppp active find where service="pppoe"]
:local currentState [:toarray ""]

:foreach id in=$activePPPoE do={
    :local name [/ppp active get $id name]
    :local callerId [/ppp active get $id caller-id]
    :local address [/ppp active get $id address]
    :local uptime [/ppp active get $id uptime]
    :local info "$callerId|$address|$uptime"
    :set ($currentState->$name) $info

    :if ([:typeof ($botPppoeState->$name)] = "nothing") do={
        :local msg "\F0\9F\9F\A2 <b>PPPoE Connect</b>%0AUser: $name%0ACaller-ID: $callerId%0AIP: $address"
        :local url "https://api.telegram.org/bot$botToken/sendMessage"
        :local data "chat_id=$botChatId&text=$msg&parse_mode=HTML"
        /tool fetch url="$url" http-method=post http-data="$data" mode=https keep-result=no
    }
}

:foreach name,data in=$botPppoeState do={
    :if ([:typeof ($currentState->$name)] = "nothing") do={
        :local partsLen [:len $data]
        :local p1 [:find $data "|" 0]
        :if ($p1 < $partsLen) do={
            :local rest1 [:pick $data ($p1 + 1) $partsLen]
            :local p2 [:find $rest1 "|" 0]
            :if ($p2 >= 0) do={
                :local address [:pick $rest1 0 $p2]
                :local callerId [:pick $data 0 $p1]
                :local msg "\F0\9F\94\B4 <b>PPPoE Disconnect</b>%0AUser: $name%0ACaller-ID: $callerId%0AIP: $address"
                :local url "https://api.telegram.org/bot$botToken/sendMessage"
                :local data "chat_id=$botChatId&text=$msg&parse_mode=HTML"
                /tool fetch url="$url" http-method=post http-data="$data" mode=https keep-result=no
            }
        }
    }
}

:global botPppoeState $currentState
}

# =============================================================================
#  [4/5] MONITOR: bot-iface-mon — interface up/down
# =============================================================================
/system script remove [find name="bot-iface-mon"]
/system script add name="bot-iface-mon" owner="admin" policy=read,write,policy,test source={
:global botToken
:global botChatId
:global botIfaceState
:if ([:typeof $botIfaceState] != "array") do={ :global botIfaceState [:toarray ""] }

:local interfaces [/interface find where dynamic=no]
:local currentState [:toarray ""]

:foreach id in=$interfaces do={
    :local name [/interface get $id name]
    :local type [/interface get $id type]
    :local running [/interface get $id running]

    :if ($type = "bridge" or $type = "ether" or $type = "vlan" or $type = "pppoe-out" or $type = "wlan") do={
        :set ($currentState->$name) $running
        :local prevRunning ($botIfaceState->$name)
        :if ($prevRunning != $running and [:typeof $prevRunning] != "nothing") do={
            :if ($running = true) do={
                :local msg "\F0\9F\9F\A2 <b>Interface UP</b>%0AName: $name%0AType: $type"
                :local url "https://api.telegram.org/bot$botToken/sendMessage"
                :local data "chat_id=$botChatId&text=$msg&parse_mode=HTML"
                /tool fetch url="$url" http-method=post http-data="$data" mode=https keep-result=no
            } else={
                :local msg "\F0\9F\94\B4 <b>Interface DOWN</b>%0AName: $name%0AType: $type"
                :local url "https://api.telegram.org/bot$botToken/sendMessage"
                :local data "chat_id=$botChatId&text=$msg&parse_mode=HTML"
                /tool fetch url="$url" http-method=post http-data="$data" mode=https keep-result=no
            }
        }
    }
}

:global botIfaceState $currentState
}

# =============================================================================
#  [5/5] STARTUP: bot-startup — inisialisasi + notifikasi reboot
# =============================================================================
/system script remove [find name="bot-startup"]
/system script add name="bot-startup" owner="admin" policy=read,write,policy,test source={
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
}

# =============================================================================
#  SCHEDULER
# =============================================================================
/system scheduler remove [find name="bot-hotspot-sched"]
/system scheduler remove [find name="bot-pppoe-sched"]
/system scheduler remove [find name="bot-iface-sched"]
/system scheduler remove [find name="bot-startup-sched"]

/system scheduler add name="bot-hotspot-sched" interval=10s on-event="/system script run bot-hotspot-mon" start-time=startup
/system scheduler add name="bot-pppoe-sched" interval=30s on-event="/system script run bot-pppoe-mon" start-time=startup
/system scheduler add name="bot-iface-sched" interval=30s on-event="/system script run bot-iface-mon" start-time=startup
/system scheduler add name="bot-startup-sched" start-time=startup on-event="/system script run bot-startup"

:put "====================================================="
:put " Bot MikroTik Telegram v2.0 — Installed!"
:put "====================================================="
:put " Tes: /system script run bot-startup"
:put "====================================================="
