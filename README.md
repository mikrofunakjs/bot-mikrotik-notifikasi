# 🤖 Bot Notifikasi MikroTik → Telegram

Bot notifikasi **satu arah** dari MikroTik ke Telegram. 100% berjalan di dalam RouterOS — **tanpa server, tanpa API eksternal, tanpa container**.

Cukup copy-paste source script ke Winbox, atau import satu file `.rsc`.

---

## ✨ Fitur

| Event | Status |
|---|---|
| Hotspot voucher login / logout | 🟢 🔴 |
| PPPoE client connect / disconnect | 🟢 🔴 |
| Interface up / down | 🟢 🔴 |
| Router reboot / startup | 🔄 |

---

## 📋 Syarat

- MikroTik RouterOS v6.45+ / v7+
- Koneksi internet (router bisa resolve `api.telegram.org`)
- Bot Telegram (bikin gratis via [@BotFather](https://t.me/BotFather))

---

## 🚀 Install — Pilih Metode

### Metode A: Import File (termudah)

1. **Ganti token & chat ID** — buka `bot-mikrotik-telegram.rsc`, cari `bot-config`, ganti:
   ```
   :global botToken "TOKEN_KAMU"
   :global botChatId "CHAT_ID_KAMU"
   ```
2. **Upload** ke MikroTik: Winbox → Files → drag file `.rsc`
3. **Terminal**: `/import file=bot-mikrotik-telegram.rsc`
4. Selesai.

### Metode B: Winbox GUI (step-by-step, kalau import error)

Buka Winbox → **System → Scripts**. Untuk setiap script di bawah, klik **Add (+)**:

#### Step 1: Ganti Token
Buka file `scripts/01-bot-config.rsc` → ganti `botToken` dan `botChatId`.

#### Step 2: Bikin 6 Script
| # | Name | Source dari file | Policy |
|---|---|---|---|
| 1 | `bot-config` | `scripts/01-bot-config.rsc` | read, write, policy, test |
| 2 | `bot-send` | `scripts/02-bot-send.rsc` | read, write, policy, test |
| 3 | `bot-hotspot-mon` | `scripts/03-bot-hotspot-mon.rsc` | read, write, policy, test |
| 4 | `bot-pppoe-mon` | `scripts/04-bot-pppoe-mon.rsc` | read, write, policy, test |
| 5 | `bot-iface-mon` | `scripts/05-bot-iface-mon.rsc` | read, write, policy, test |
| 6 | `bot-startup` | `scripts/06-bot-startup.rsc` | read, write, policy, test |

> **Caranya:** Buka file `.rsc`, copy SEMUA isinya, paste ke kolom **Source** di Winbox.

#### Step 3: Pasang Scheduler
Buka **Terminal**, copy-paste satu per satu:
```
/system scheduler add name="bot-hotspot-sched" interval=10s on-event="/system script run bot-hotspot-mon" start-time=startup

/system scheduler add name="bot-pppoe-sched" interval=30s on-event="/system script run bot-pppoe-mon" start-time=startup

/system scheduler add name="bot-iface-sched" interval=30s on-event="/system script run bot-iface-mon" start-time=startup

/system scheduler add name="bot-startup-sched" start-time=startup on-event="/system script run bot-startup"
```

Atau import: upload `scripts/setup-schedulers.rsc`, lalu `/import file=setup-schedulers.rsc`.

---

## ✅ Verifikasi

**Terminal MikroTik:**
```
/system script run bot-startup
```

Cek Telegram — harus muncul notifikasi "Router Started".

Cek semua script:
```
/system script print
```

Cek scheduler:
```
/system scheduler print
```

---

## 🔧 Troubleshooting

| Masalah | Solusi |
|---|---|
| "expected end of command" pas copy-paste | **Jangan paste ke terminal.** Pakai Winbox GUI (System → Scripts → Add) — paste ke kolom Source. |
| Bot tidak kirim notifikasi | Cek `/log print` — cari error "bot-send" |
| Gagal resolve api.telegram.org | `ping api.telegram.org` dari router |
| Pesan tidak muncul di Telegram | Cek `botToken` dan `botChatId` — buka `/getUpdates` lagi |
| "Router Started" muncul setelah reboot | Normal — state di-reset. Notifikasi hanya sekali. |

---

## ⚙️ Kustomisasi

### Ganti interval polling
```
/system scheduler set bot-hotspot-sched interval=5s
```

### Stop monitor sementara
```
/system scheduler disable bot-hotspot-sched,bot-pppoe-sched,bot-iface-sched
```

---

## 📁 Struktur File

```
bot-mikrotik-notifikasi/
├── bot-mikrotik-telegram.rsc       ← Import all-in-one
├── scripts/                         ← Winbox GUI step-by-step
│   ├── 01-bot-config.rsc
│   ├── 02-bot-send.rsc
│   ├── 03-bot-hotspot-mon.rsc
│   ├── 04-bot-pppoe-mon.rsc
│   ├── 05-bot-iface-mon.rsc
│   ├── 06-bot-startup.rsc
│   └── setup-schedulers.rsc
├── README.md
├── LICENSE
└── .gitignore
```

---

## 📝 Lisensi

MIT © 2026 akjsteknik
