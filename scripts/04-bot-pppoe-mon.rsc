# =============================================================================
#  bot-pppoe-mon — deteksi PPPoE client connect/disconnect
# =============================================================================
#  Cara pakai:
#   Winbox → System → Scripts → Add (+)
#     Name: bot-pppoe-mon
#     Policy: read, write, policy, test
#   Copy-paste isi di bawah ke kolom Source, OK.
# =============================================================================

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
