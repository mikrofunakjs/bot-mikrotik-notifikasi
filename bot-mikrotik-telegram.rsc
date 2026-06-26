# =============================================================================
#  Bot Notifikasi MikroTik → Telegram
#  =============================================================================
#  File: bot-mikrotik-telegram.rsc
#  Version: 1.1.0 — Winbox Terminal Safe
#  Repo: https://github.com/mikrofunakjs/bot-mikrotik-notifikasi
#  =============================================================================
#  CARA PAKAI (Winbox):
#    1. Ubah BOT_TOKEN dan CHAT_ID di bawah
#    2. Upload file ini ke MikroTik (Winbox → Files → Upload)
#    3. Terminal: /import file=bot-mikrotik-telegram.rsc
#  =============================================================================
#  CARA PAKAI (SSH):
#    1. Upload via SCP ke router
#    2. /import file=bot-mikrotik-telegram.rsc
#  =============================================================================

# =============================================================================
#  [1/6] KONFIGURASI — WAJIB DIGANTI
# =============================================================================
/system script remove [find name="bot-config"]
/system script add name="bot-config" owner="admin" policy=read,write,policy,test source={
##### GANTI DI BAWAH INI #####
:global botToken "123456:ABC-DEF1234ghijklmnop"
:global botChatId "123456789"
##### STOP GANTI #############
:global botName "MikroTik-Notifikasi"
}

# =============================================================================
#  [2/6] HELPER: bot-send — fungsi kirim pesan via Telegram
#         Dipanggil sebagai $botSend "pesan"
# =============================================================================
/system script remove [find name="bot-send"]
/system script add name="bot-send" owner="admin" policy=read,write,policy,test source={
:global botToken
:global botChatId
:global botSend do={
    :global botToken
    :global botChatId
    :local msg $0
    :local url "https://api.telegram.org/bot$botToken/sendMessage"
    :local data "chat_id=$botChatId&text=$msg&parse_mode=HTML"
    :do {
        /tool fetch url="$url" http-method=post http-data="$data" mode=https keep-result=no
    } on-error={
        :log warning "bot-send: Gagal kirim ke Telegram"
    }
}
}

# =============================================================================
#  [3/6] MONITOR: bot-hotspot-mon — deteksi voucher login/logout
# =============================================================================
/system script remove [find name="bot-hotspot-mon"]
/system script add name="bot-hotspot-mon" owner="admin" policy=read,write,policy,test source={
:global botHotspotState
:global botSend
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
        $botSend $msg
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
                $botSend $msg
            }
        }
    }
}

:global botHotspotState $currentState
}

# =============================================================================
#  [4/6] MONITOR: bot-pppoe-mon — deteksi PPPoE connect/disconnect
# =============================================================================
/system script remove [find name="bot-pppoe-mon"]
/system script add name="bot-pppoe-mon" owner="admin" policy=read,write,policy,test source={
:global botPppoeState
:global botSend
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
        $botSend $msg
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
                $botSend $msg
            }
        }
    }
}

:global botPppoeState $currentState
}

# =============================================================================
#  [5/6] MONITOR: bot-iface-mon — deteksi interface up/down
# =============================================================================
/system script remove [find name="bot-iface-mon"]
/system script add name="bot-iface-mon" owner="admin" policy=read,write,policy,test source={
:global botIfaceState
:global botSend
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
                $botSend $msg
            } else={
                :local msg "\F0\9F\94\B4 <b>Interface DOWN</b>%0AName: $name%0AType: $type"
                $botSend $msg
            }
        }
    }
}

:global botIfaceState $currentState
}

# =============================================================================
#  [6/6] STARTUP: bot-startup — inisialisasi saat router reboot
# =============================================================================
/system script remove [find name="bot-startup"]
/system script add name="bot-startup" owner="admin" policy=read,write,policy,test source={
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
:put " Bot MikroTik Telegram v1.1.0 — Installed!"
:put "====================================================="
:put " Scripts: [/system script print count-only] loaded"
:put " Schedulers: [/system scheduler print count-only where name~\"bot\"] active"
:put ""
:put " Tes: /system script run bot-startup"
:put "====================================================="
