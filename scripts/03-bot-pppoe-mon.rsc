# =============================================================================
#  bot-pppoe-mon — deteksi PPPoE connect/disconnect
# =============================================================================
#  Winbox: System → Scripts → Add (+)
#    Name: bot-pppoe-mon
#    Policy: read, write, policy, test
#    Source: copy-paste isi file ini

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
