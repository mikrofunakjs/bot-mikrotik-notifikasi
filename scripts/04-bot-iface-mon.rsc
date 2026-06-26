# =============================================================================
#  bot-iface-mon — deteksi interface up/down
# =============================================================================
#  Winbox: System → Scripts → Add (+)
#    Name: bot-iface-mon
#    Policy: read, write, policy, test
#    Source: copy-paste isi file ini

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
