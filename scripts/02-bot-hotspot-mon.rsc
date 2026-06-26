# =============================================================================
#  bot-hotspot-mon — deteksi voucher login/logout
# =============================================================================
#  Winbox: System → Scripts → Add (+)
#    Name: bot-hotspot-mon
#    Policy: read, write, policy, test
#    Source: copy-paste isi file ini

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
