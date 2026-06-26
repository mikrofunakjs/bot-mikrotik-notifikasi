# =============================================================================
#  bot-iface-mon — deteksi interface up/down
# =============================================================================
#  Cara pakai:
#   Winbox → System → Scripts → Add (+)
#     Name: bot-iface-mon
#     Policy: read, write, policy, test
#   Copy-paste isi di bawah ke kolom Source, OK.
# =============================================================================

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
