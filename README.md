# 0xygen-esim (`hyfetrial`)

CLI ringan untuk klaim **eSIM Trial HYFE** (XL Prioritas) dari OpenWrt
maupun Linux biasa. Murni `sh` + `curl` + `jq`, tanpa kompilasi.

[![build](https://github.com/nyawitniorang/0xygen-esim/actions/workflows/build.yml/badge.svg)](https://github.com/nyawitniorang/0xygen-esim/actions/workflows/build.yml)

## Quick start

```sh
hyfetrial          # mode interaktif - tanya semua
```

Atau pakai flag:

```sh
hyfetrial --name "Andi P" --whatsapp 81234567890 \
          --email saya@gmail.com \
          --eid 12345678901234567890123456789012 \
          --pattern 8888 --yes
```

`hyfetrial --help` untuk daftar flag, `hyfetrial --config` untuk lihat
config aktif.

## Install

### OpenWrt — paket pre-built dari [Releases](https://github.com/nyawitniorang/0xygen-esim/releases)

```sh
# OpenWrt 24.10 (opkg)
opkg update && opkg install curl jq ca-bundle
opkg install ./hyfetrial_0.1.1-*_all.ipk

# OpenWrt 25 SNAPSHOT (apk)
apk update && apk add curl jq ca-bundles
apk add --allow-untrusted ./hyfetrial-0.1.1-r*.apk
```

### Linux biasa

```sh
git clone https://github.com/nyawitniorang/0xygen-esim.git
cd 0xygen-esim
sudo make install                 # ke /usr/local
# atau langsung: ./src/hyfetrial
```

Pastikan `curl` dan `jq` terpasang.

Untuk build paket OpenWrt sendiri, lihat komentar di
[`openwrt/hyfetrial/Makefile`](openwrt/hyfetrial/Makefile).

## Config

Setting captcha/IMAP/email/EID disimpan di `/etc/hyfetrial/config` dan
otomatis di-load. Run pertama tanpa config akan menawarkan wizard setup.

```sh
hyfetrial --new-config        # wizard semua field
hyfetrial --captcha-config    # captcha mode + API key
hyfetrial --imap-config       # server IMAP
hyfetrial --email-config      # tambah/hapus akun email
hyfetrial --config            # lihat config (password ter-mask)
```

Multi-akun email, multi-EID, dan per-provider captcha key didukung —
saat prompt interaktif, hyfetrial menampilkan menu pilihan dari config.
Lihat [`etc/config.example`](etc/config.example) untuk semua key yang
tersedia.

CLI flag selalu menang atas config file. Override path config lain via
`--config /path/lain` atau `HYFE_DEFAULT_CONFIG=/path/lain`.

## Captcha

| Mode          | Cara kerja                                       | Biaya    |
| ------------- | ------------------------------------------------ | -------- |
| `manual`      | Paste token `grecaptcha.getResponse()` (default) | gratis   |
| `nextcaptcha` | API <https://nextcaptcha.com/>                   | **free trial** via [@nextcaptcha_free_trial_bot](https://t.me/nextcaptcha_free_trial_bot), then $0.6/1000 |
| `2captcha`    | API <https://2captcha.com/>                      | min $1, $1-2.99/1000 |
| `anticaptcha` | API <https://anti-captcha.com/>                  | min $5, ~$2/1000 |
| `capsolver`   | API <https://capsolver.com/>                     | min $5, $1/1000 |

## OTP

| Mode      | Cara kerja                                                   |
| --------- | ------------------------------------------------------------ |
| `manual`  | Ketik OTP 6 karakter di terminal (default)                   |
| `imap`    | Polling IMAP via curl, auto-ambil OTP dari email terbaru     |

OpenWrt note: `imap` butuh curl dengan IMAP enabled. Cek `curl -V` —
baris `Protocols:` harus berisi `imap imaps`. Kalau tidak, pakai
`manual` atau rebuild curl/libcurl dengan `CONFIG_LIBCURL_IMAP=y`.

## Catatan

- reCAPTCHA Enterprise tidak bisa di-bypass; solver berbayar atau paste
  manual adalah satu-satunya jalur yang stabil.
- Token reCAPTCHA valid ~2 menit setelah dicentang.
- EID harus dari device yang akan dipakai. QR eSIM yang terbit hanya
  bisa diaktifkan di HP yang EID-nya dimasukkan saat klaim.
- Tools ini cuma membungkus API publik yang sudah ada di web HYFE.

## Pengembangan

```sh
make lint    # shellcheck -s sh src/...
make test    # smoke: --help, --list-numbers
```

## Lisensi

MIT — lihat [LICENSE](LICENSE).
