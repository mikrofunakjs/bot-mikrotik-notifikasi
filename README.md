# 🤖 Bot Notifikasi MikroTik → Telegram

Bot notifikasi **satu arah** dari MikroTik ke Telegram. 100% berjalan di dalam RouterOS — **tanpa server, tanpa API eksternal, tanpa container, tanpa script di PC**.

Cukup satu file `.rsc` — copy-paste atau import ke MikroTik, langsung jalan.

---

## ✨ Fitur

| Event | Emoji | Interval Polling |
|---|---|---|
| Hotspot voucher login / logout | 🟢 🔴 | 10 detik |
| PPPoE client connect / disconnect | 🟢 🔴 | 30 detik |
| Interface up / down | 🟢 🔴 | 30 detik |
| Router reboot / startup | 🔄 | Saat boot |

Semua notifikasi dikirim via Bot Telegram API dengan format HTML.

---

## 📋 Persyaratan

- **MikroTik RouterOS v6.45+ atau v7+**
- **Koneksi internet** (router bisa resolve `api.telegram.org`)
- **Port 443 outbound** tidak di-block firewall
- **Bot Telegram** (bikin gratis via [@BotFather](https://t.me/BotFather))

---

## 🚀 Cara Install (2 Langkah)

### Langkah 1: Bikin Bot Telegram + Dapatkan Chat ID

1. Buka Telegram, cari **[@BotFather](https://t.me/BotFather)**
2. Kirim `/newbot`, ikuti instruksi
3. Catat **BOT_TOKEN** yang diberikan (format: `123456:ABC-DEF...`)
4. Cari bot kamu, kirim `/start`, lalu kirim pesan apa saja
5. Buka browser:
   ```
   https://api.telegram.org/bot<BOT_TOKEN>/getUpdates
   ```
6. Cari `"chat":{"id":123456789}` → catat angka ini sebagai **CHAT_ID**

> **Opsional untuk group:** Tambahkan bot ke group Telegram, kirim pesan di group, cek `/getUpdates` lagi. Chat ID group biasanya negatif (contoh: `-400123456789`).

### Langkah 2: Install di MikroTik

**Cara A: Import file (via Winbox/WebFig)**

1. Upload `bot-mikrotik-telegram.rsc` ke router (Winbox → Files → Upload)
2. Buka **New Terminal** (Winbox) atau SSH
3. Jalankan:
   ```
   /import file=bot-mikrotik-telegram.rsc
   ```

**Cara B: Copy-paste manual (via Terminal/SSH)**

1. Buka file `bot-mikrotik-telegram.rsc` dengan text editor
2. **Ganti** `botToken` dan `botChatId` di bagian `bot-config`:
   ```
   :global botToken "123456:ABC-DEF1234ghijklmnop"    ← ganti
   :global botChatId "123456789"                       ← ganti
   ```
3. Copy SEMUA isi file
4. Paste ke terminal MikroTik (Winbox/SSH/WebFig)
5. Enter

---

## ✅ Verifikasi

Jalankan perintah ini di terminal MikroTik:

```
/system script run bot-send "✅ Bot aktif! Tes dari MikroTik."
```

Cek Telegram — harus muncul pesan dari bot.

Cek scheduler jalan:
```
/system scheduler print
```

Cek script terpasang:
```
/system script print
```

---

## 🔧 Troubleshooting

| Masalah | Solusi |
|---|---|
| Bot tidak kirim notifikasi | Cek `/log print` — lihat error "bot-send" |
| Gagal resolve api.telegram.org | Pastikan DNS jalan: `ping api.telegram.org` dari router |
| Pesan tidak muncul di Telegram | Cek `botToken` dan `botChatId` — jalankan `/getUpdates` lagi |
| Setelah reboot, semua user hotspot di-spam "login" | Normal. State di-reset saat reboot. Notifikasi hanya muncul sekali. |
| "no such item" di log | Mungkin script belum jalan — jalankan dulu: `/system script run bot-startup` |

---

## ⚙️ Kustomisasi

### Ganti interval polling

```
/system scheduler set bot-hotspot-sched interval=5s    # lebih cepat
/system scheduler set bot-pppoe-sched interval=60s     # lebih lambat
```

### Stop monitor sementara

```
/system scheduler disable bot-hotspot-sched
/system scheduler disable bot-pppoe-sched
/system scheduler disable bot-iface-sched
```

### Tambah interface yang dimonitor

Edit script `bot-iface-mon`, tambahkan di baris filter:
```
:if ($type = "bridge" or $type = "ether" or $type = "vlan" or $type = "pppoe-out" or $type = "wlan" or $type = "wg") do={
```

### Tambah notifikasi lain (contoh: CPU high)

Bisa tambahkan script baru + scheduler untuk monitor `/system resource`:
```
:local cpu [/system resource get cpu-load]
:if ($cpu > 80) do={
    /system script run bot-send "⚠️ CPU Usage: $cpu%"
}
```

---

## 📁 Struktur File

```
bot-mikrotik-telegram/
├── bot-mikrotik-telegram.rsc    ← File utama (import ke MikroTik)
├── README.md                     ← Dokumentasi ini
└── LICENSE                       ← MIT
```

---

## ⚠️ Batasan

- **Polling-based**, bukan event-driven. Ada kemungkinan user login lalu logout dalam <10 detik tidak terdeteksi.
- **Variabel global hilang saat reboot.** Startup script menginisialisasi ulang → semua user yang sedang online akan dikirim notifikasi "login baru" setelah reboot (sekali saja).
- RouterOS tidak auto-encode URL karakter khusus. Username dengan `&`, `=`, `%` bisa menyebabkan pesan rusak.

---

## 📝 Lisensi

MIT © 2026 akjsteknik — Bebas pakai, modifikasi, distribusi.

---

## 🔗 Link

- [MikroTik Scripting Docs](https://help.mikrotik.com/docs/display/ROS/Scripting)
- [Telegram Bot API](https://core.telegram.org/bots/api)
- [@BotFather](https://t.me/BotFather)
