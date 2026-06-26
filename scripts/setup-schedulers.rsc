# =============================================================================
#  Scheduler — jalankan di Terminal MikroTik
# =============================================================================
#   Copy-paste baris-baris di bawah ke terminal satu per satu.
#   Atau upload file ini lalu: /import file=setup-schedulers.rsc
# =============================================================================

/system scheduler remove [find name="bot-hotspot-sched"]
/system scheduler remove [find name="bot-pppoe-sched"]
/system scheduler remove [find name="bot-iface-sched"]
/system scheduler remove [find name="bot-startup-sched"]

/system scheduler add name="bot-hotspot-sched" interval=10s on-event="/system script run bot-hotspot-mon" start-time=startup
/system scheduler add name="bot-pppoe-sched" interval=30s on-event="/system script run bot-pppoe-mon" start-time=startup
/system scheduler add name="bot-iface-sched" interval=30s on-event="/system script run bot-iface-mon" start-time=startup
/system scheduler add name="bot-startup-sched" start-time=startup on-event="/system script run bot-startup"

:put "Schedulers installed! [/system scheduler print count-only where name~\"bot\"] active"
