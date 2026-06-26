# 🤖 Bot Notifikasi MikroTik → Telegram v2.0

Bot notifikasi **satu arah** dari MikroTik ke Telegram. 100% berjalan di dalam RouterOS — **tanpa server, tanpa API eksternal, tanpa container**.

---

## ✨ Fitur

| Event | Notifikasi |
|---|---|
| Hotspot voucher login / logout | 🟢 🔴 |
| PPPoE client connect / disconnect | 🟢 🔴 |
| Interface up / down | 🟢 🔴 |
| Router reboot / startup | 🔄 |

---

## 🚀 Cara Install

### Metode A: Import File (termudah)

1. **Ganti token & chat ID** — buka `bot-mikrotik-telegram.rsc`, cari `bot-config`, ganti:
   ```
   :global botToken "TOKEN_KAMU"
   :global botChatId "CHAT_ID_KAMU"
   ```
2. **Upload** ke MikroTik: Winbox → Files → Upload (drag file `.rsc`)
3. **Terminal**: `/import file=bot-mikrotik-telegram.rsc`
4. Selesai.

### Metode B: Winbox GUI (step-by-step)

Buka Winbox → **System → Scripts**. Untuk setiap script klik **Add (+)**:

| # | Name | Source dari | Policy |
|---|---|---|---|
| 1 | `bot-config` | `scripts/01-bot-config.rsc` | read, write, policy, test |
| 2 | `bot-hotspot-mon` | `scripts/02-bot-hotspot-mon.rsc` | read, write, policy, test |
| 3 | `bot-pppoe-mon` | `scripts/03-bot-pppoe-mon.rsc` | read, write, policy, test |
| 4 | `bot-iface-mon` | `scripts/04-bot-iface-mon.rsc` | read, write, policy, test |
| 5 | `bot-startup` | `scripts/05-bot-startup.rsc` | read, write, policy, test |

> **Catatan:** `bot-config` harus diisi token & chat ID dulu. Script lain sudah inline — tidak ada ketergantungan antar-script.

### Pasang Scheduler

Buka **Terminal**, copy satu per satu:

```
/system scheduler add name="bot-hotspot-sched" interval=10s on-event="/system script run bot-hotspot-mon" start-time=startup
/system scheduler add name="bot-pppoe-sched" interval=30s on-event="/system script run bot-pppoe-mon" start-time=startup
/system scheduler add name="bot-iface-sched" interval=30s on-event="/system script run bot-iface-mon" start-time=startup
/system scheduler add name="bot-startup-sched" start-time=startup on-event="/system script run bot-startup"
```

---

## ✅ Verifikasi

Jalankan di terminal:

```
/system script run bot-startup
```

Cek Telegram — harus muncul "Router Started".

---

## 🔧 Troubleshooting

| Masalah | Solusi |
|---|---|
| Pesan `$botSend` muncul di Telegram (bukan isi notifikasi) | **Kamu pakai versi lama.** Update semua script ke v2.0 (tarik ulang dari repo). |
| Bot tidak kirim notifikasi | Run dulu `bot-config`: `/system script run bot-config` |
| 404 Fetch failed | Token/chat ID salah. Cek: `:put $botToken` |
| Setelah reboot tidak ada notifikasi | Cek scheduler: `startup-sched` harus jalan saat boot |

---

## ⚙️ Arsitektur v2.0

Setiap script monitor **berdiri sendiri** — tidak ada fungsi, tidak ada `$botSend`, tidak ada cross-script call. Masing-masing langsung panggil `/tool fetch` ke Telegram API. Token & chat ID diambil dari variabel global (`$botToken`, `$botChatId`) yang diset oleh `bot-config`.

```
bot-config ─── :global botToken, botChatId
     │
     ├── bot-hotspot-mon ─── /tool fetch (inline)
     ├── bot-pppoe-mon    ─── /tool fetch (inline)
     ├── bot-iface-mon    ─── /tool fetch (inline)
     └── bot-startup      ─── /tool fetch (inline) + reset state
```

---

## 📁 Struktur

```
├── bot-mikrotik-telegram.rsc     ← All-in-one import
├── scripts/                       ← Winbox GUI per-script
│   ├── 01-bot-config.rsc
│   ├── 02-bot-hotspot-mon.rsc
│   ├── 03-bot-pppoe-mon.rsc
│   ├── 04-bot-iface-mon.rsc
│   ├── 05-bot-startup.rsc
│   └── setup-schedulers.rsc
├── README.md
└── LICENSE
```

---

## 📝 Lisensi

MIT © 2026 akjsteknik
