# =============================================================================
#  Bot Notifikasi MikroTik → Telegram
#  =============================================================================
#  File: bot-mikrotik-telegram.rsc
#  Version: 1.0.0
#  Author: akjsteknik
#  Repo: https://github.com/akjsteknik/bot-telegram-mikrotik
#  =============================================================================
#  CARA PAKAI:
#    1. Ganti BOT_TOKEN dan CHAT_ID di script "bot-config" di bawah
#    2. Copy-paste SEMUA isi file ini ke terminal MikroTik (Winbox/SSH/WebFig)
#       atau upload ke router lalu: /import file=bot-mikrotik-telegram.rsc
#    3. Selesai! Cek /system script dan /system scheduler
#  =============================================================================
#  Yang dimonitor:
#    • Hotspot — voucher connect/disconnect
#    • PPPoE   — client connect/disconnect
#    • Interface — up/down (ether, bridge, vlan, pppoe-out)
#    • System  — reboot/startup
#  =============================================================================

# =============================================================================
#  KONFIGURASI — WAJIB DIGANTI
#  Dapatkan BOT_TOKEN dari @BotFather di Telegram
#  Dapatkan CHAT_ID dari https://api.telegram.org/bot<TOKEN>/getUpdates
# =============================================================================
/system script remove [find name="bot-config"]
/system script add name="bot-config" owner="admin" policy=read,write,policy,test source={
##### GANTI DI SINI #####
:global botToken "123456:ABC-DEF1234ghijklmnop"
:global botChatId "123456789"
##### END GANTI #######
:global botName "MikroTik-Notifikasi"
}

# =============================================================================
#  HELPER: bot-send — kirim pesan ke Telegram
#  Parameter: pesan (string) — $0
# =============================================================================
/system script remove [find name="bot-send"]
/system script add name="bot-send" owner="admin" policy=read,write,policy,test source={
:global botToken
:global botChatId
:local message $0
:local url "https://api.telegram.org/bot$botToken/sendMessage"
:local data "chat_id=$botChatId&text=$message&parse_mode=HTML"
:do {
    /tool fetch url="$url" http-method=post http-data="$data" mode=https keep-result=no
} on-error={
    :log warning "bot-send: Gagal kirim ke Telegram"
}
}

# =============================================================================
#  MONITOR: bot-hotspot-mon — deteksi voucher login/logout
#  Bandingkan /ip hotspot active sekarang vs state sebelumnya
# =============================================================================
/system script remove [find name="bot-hotspot-mon"]
/system script add name="bot-hotspot-mon" owner="admin" policy=read,write,policy,test source={
:global botHotspotState
:if ([:typeof $botHotspotState] != "array") do={ :global botHotspotState [:toarray ""] }

# Ambil daftar user hotspot aktif sekarang
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

    # User ada sekarang, tidak ada sebelumnya = LOGIN
    :if ([:typeof ($botHotspotState->$user)] = "nothing") do={
        :local msg "\F0\9F\9F\A2 <b>Hotspot Login</b>%0AUser: $user%0AServer: $server%0AIP: $address%0AMAC: $mac"
        /system script run bot-send "$msg"
    }
}

# Cek user yang ada sebelumnya tapi tidak ada sekarang = LOGOUT
:foreach user,data in=$botHotspotState do={
    :if ([:typeof ($currentState->$user)] = "nothing") do={
        :local partsLen [:len $data]
        :local p1 [:find $data "|" 0]
        :local rest1 [:pick $data ($p1 + 1) $partsLen]
        :local p2 [:find $rest1 "|" 0]
        :local address [:pick $rest1 0 $p2]
        :local rest2 [:pick $rest1 ($p2 + 1) [:len $rest1]]
        :local mac rest2
        :local msg "\F0\9F\94\B4 <b>Hotspot Logout</b>%0AUser: $user%0AIP: $address%0AMAC: $mac"
        /system script run bot-send "$msg"
    }
}

# Simpan state untuk pengecekan berikutnya
:global botHotspotState $currentState
}

# =============================================================================
#  MONITOR: bot-pppoe-mon — deteksi PPPoE connect/disconnect
#  Bandingkan /ppp active (service=pppoe) sekarang vs state sebelumnya
# =============================================================================
/system script remove [find name="bot-pppoe-mon"]
/system script add name="bot-pppoe-mon" owner="admin" policy=read,write,policy,test source={
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
        /system script run bot-send "$msg"
    }
}

:foreach name,data in=$botPppoeState do={
    :if ([:typeof ($currentState->$name)] = "nothing") do={
        :local partsLen [:len $data]
        :local p1 [:find $data "|" 0]
        :local rest1 [:pick $data ($p1 + 1) $partsLen]
        :local p2 [:find $rest1 "|" 0]
        :local address [:pick $rest1 0 $p2]
        :local callerId [:pick $data 0 $p1]
        :local msg "\F0\9F\94\B4 <b>PPPoE Disconnect</b>%0AUser: $name%0ACaller-ID: $callerId%0AIP: $address"
        /system script run bot-send "$msg"
    }
}

:global botPppoeState $currentState
}

# =============================================================================
#  MONITOR: bot-iface-mon — deteksi interface up/down
#  Cek flag "running" pada interface fisik
#  Skip: dynamic, loopback, wireless (bisa ditambah filter sendiri)
# =============================================================================
/system script remove [find name="bot-iface-mon"]
/system script add name="bot-iface-mon" owner="admin" policy=read,write,policy,test source={
:global botIfaceState
:if ([:typeof $botIfaceState] != "array") do={ :global botIfaceState [:toarray ""] }

# Hanya monitor interface non-dynamic
:local interfaces [/interface find where dynamic=no]
:local currentState [:toarray ""]

:foreach id in=$interfaces do={
    :local name [/interface get $id name]
    :local type [/interface get $id type]
    :local running [/interface get $id running]

    # Hanya monitor tipe interface yang umum (skip vrrp, lte, wireless jika tidak perlu)
    :if ($type = "bridge" or $type = "ether" or $type = "vlan" or $type = "pppoe-out" or $type = "wlan") do={
        :set ($currentState->$name) $running

        :local prevRunning ($botIfaceState->$name)
        :if ($prevRunning != $running and [:typeof $prevRunning] != "nothing") do={
            :if ($running = true) do={
                :local msg "\F0\9F\9F\A2 <b>Interface UP</b>%0AName: $name%0AType: $type"
                /system script run bot-send "$msg"
            } else={
                :local msg "\F0\9F\94\B4 <b>Interface DOWN</b>%0AName: $name%0AType: $type"
                /system script run bot-send "$msg"
            }
        }
    }
}

:global botIfaceState $currentState
}

# =============================================================================
#  STARTUP: bot-startup — inisialisasi saat router reboot
#  Reset state agar tidak spam, kirim notifikasi startup
# =============================================================================
/system script remove [find name="bot-startup"]
/system script add name="bot-startup" owner="admin" policy=read,write,policy,test source={
# Load konfigurasi
/system script run bot-config

# Reset semua state (supaya tidak spam notifikasi setelah reboot)
:global botHotspotState [:toarray ""]
:global botPppoeState [:toarray ""]
:global botIfaceState [:toarray ""]

# Kirim notifikasi startup
:local identity [/system identity get name]
:local uptime [/system resource get uptime]
:local version [/system resource get version]
:local clock [/system clock get time]
:local msg "\F0\9F\94\84 <b>Router Started</b>%0AName: $identity%0AVersion: $version%0ATime: $clock"
/system script run bot-send "$msg"
}

# =============================================================================
#  SCHEDULER — jalankan monitor secara berkala
# =============================================================================
/system scheduler remove [find name="bot-hotspot-sched"]
/system scheduler remove [find name="bot-pppoe-sched"]
/system scheduler remove [find name="bot-iface-sched"]
/system scheduler remove [find name="bot-startup-sched"]

# Hotspot monitor — tiap 10 detik (lebih responsif untuk voucher)
/system scheduler add name="bot-hotspot-sched" interval=10s \
    on-event="/system script run bot-hotspot-mon" \
    start-time=startup

# PPPoE monitor — tiap 30 detik
/system scheduler add name="bot-pppoe-sched" interval=30s \
    on-event="/system script run bot-pppoe-mon" \
    start-time=startup

# Interface monitor — tiap 30 detik
/system scheduler add name="bot-iface-sched" interval=30s \
    on-event="/system script run bot-iface-mon" \
    start-time=startup

# Startup — jalan sekali saat boot
/system scheduler add name="bot-startup-sched" \
    start-time=startup \
    on-event="/system script run bot-startup"

# =============================================================================
#  VERIFIKASI
# =============================================================================
:put "============================================"
:put " Bot MikroTik Telegram — Installed!"
:put "============================================"
:put " Scripts:"
:put "   [/system script print count-only] scripts loaded"
:put " Schedulers:"
:put "   [/system scheduler print count-only where name~\"bot\"] schedulers active"
:put ""
:put " Tes kirim notifikasi:"
:put "   /system script run bot-send \"Tes dari MikroTik!\""
:put "============================================"

