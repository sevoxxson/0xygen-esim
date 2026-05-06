# 0xygen-esim (`esim`)

CLI ringan satu-paket untuk OpenWrt / Linux:

- **Manage eSIM lokal** di L850GL via `lpac` (info EID, profile list,
  switch / disable / rename / delete, download profile, process pending
  notification, recovery SIM missing).
- **Klaim eSIM Trial HYFE** (XL Prioritas) lewat menu interaktif dengan
  multi-email, multi-EID, OTP via IMAP atau paste manual, reCAPTCHA via
  paste atau solver berbayar (2captcha / anticaptcha / capsolver /
  nextcaptcha).
- **Klaim Cepat** (semi-otomatis) dengan setup preferences (email/EID/
  captcha mode/OTP mode/pattern/auto-pick MSISDN).

Murni `sh` + `curl` + `jq`, tanpa kompilasi.

> **Sejak v0.2.0**: CLI standalone `hyfetrial` dilebur ke dalam `esim`
> sebagai menu utama opsi 7 (*Klaim eSIM Trial HYFE (XL Prioritas)*).
> File config tetap di `/etc/hyfetrial/config` supaya kompatibel dengan
> setup lama.

[![build](https://github.com/nyawitniorang/0xygen-esim/actions/workflows/build.yml/badge.svg)](https://github.com/nyawitniorang/0xygen-esim/actions/workflows/build.yml)

## Quick start

```sh
esim                  # masuk ke main menu interaktif
esim --debug          # idem, dengan APDU debug log dari lpac
esim --version        # cetak versi
```

Main menu:

```
1. INFO EID & eUICC
2. Profile List ( Switch / Delete )
3. Download eSIM Profile
4. Process Pending Notification
5. LPAC Version
6. Recovery SIM Missing
7. Klaim eSIM Trial HYFE (XL Prioritas)
0. Exit
```

Pilih `7` untuk masuk ke submenu klaim HYFE:

```
── Klaim ──
1. Klaim sekarang (interaktif penuh)
2. Lihat daftar MSISDN
── Klaim Cepat ──
3. Setup Klaim Cepat
4. Klaim Cepat (pakai setup di atas)
── Config ──
5. Setup config (wizard awal full)
6. Edit captcha config
7. Edit IMAP config
8. Edit email config (multi-akun)
9. Lihat config aktif
0. Kembali ke main menu
```

## Install

### OpenWrt — paket pre-built dari [Releases](https://github.com/nyawitniorang/0xygen-esim/releases)

```sh
# OpenWrt 24.10 (opkg)
opkg update && opkg install curl jq ca-bundle
opkg install ./hyfetrial_0.2.0-*_all.ipk

# OpenWrt 25 SNAPSHOT (apk)
apk update && apk add curl jq ca-bundles
apk add --allow-untrusted ./hyfetrial-0.2.0-r*.apk
```

> Nama paket OpenWrt-nya tetap `hyfetrial` untuk kompatibilitas dengan
> feed/CI lama; binary yang ter-install sekarang adalah `/usr/bin/esim`.
> Library script ada di `/usr/lib/hyfetrial/{common,config,api,captcha,otp,hyfe}.sh`.

`lpac` harus tersedia (`/usr/bin/lpac`). Kalau belum, install dari feed
yang sesuai modem Anda atau set `LPAC_BIN` ke path lain.

### Linux biasa

```sh
git clone https://github.com/nyawitniorang/0xygen-esim.git
cd 0xygen-esim
sudo make install                 # ke /usr/local/bin/esim
# atau langsung: ./src/esim
```

Pastikan `curl` dan `jq` terpasang.

Untuk build paket OpenWrt sendiri, lihat komentar di
[`openwrt/hyfetrial/Makefile`](openwrt/hyfetrial/Makefile).

## Config

Setting captcha/IMAP/email/EID disimpan di `/etc/hyfetrial/config` dan
otomatis di-load saat masuk submenu HYFE. Run pertama tanpa config akan
menawarkan wizard setup. Akses semua wizard via menu HYFE submenu 5–9
(lihat di atas).

Lihat [`etc/config.example`](etc/config.example) untuk semua key yang
tersedia, termasuk:

- `HYFE_CAPTCHA_MODE` + per-provider key (`HYFE_CAPTCHA_KEY_*`)
- `HYFE_OTP_MODE` + setting IMAP (`HYFE_IMAP_URL`, `HYFE_IMAP_FOLDER`,
  `HYFE_IMAP_SUBJECT`, `HYFE_IMAP_TIMEOUT`)
- Multi-email slots (`HYFE_EMAIL_N` + `HYFE_IMAP_PASS_N`)
- Multi-EID slots (`HYFE_EID_N`)
- Quick-claim preferences (`HYFE_QUICK_*`) — di-set lewat *Setup Klaim
  Cepat* (submenu 3)

Multi-akun email, multi-EID, dan per-provider captcha key didukung —
saat prompt interaktif, menu klaim HYFE menampilkan pilihan dari config.

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

## Random data generator

Saat user pilih "random" di prompt nama / WhatsApp:

- **Nama**: kombinasi nama Indonesia (mis. `Andi Pratama`, `Budi Saputra`).
- **MSISDN**: 11 digit dengan prefix operator HP Indonesia nyata
  (Telkomsel 811-813/821-823/851-853, Indosat 814-816/855-858, XL
  817-819/859/877-878, Tri 895-899, Axis 831-833/838, Smartfren 881-889)
  + 8 digit acak. Setiap call ambil random prefix berbeda untuk variasi
  tinggi.

## Catatan

- reCAPTCHA Enterprise tidak bisa di-bypass; solver berbayar atau paste
  manual adalah satu-satunya jalur yang stabil.
- Token reCAPTCHA valid ~2 menit setelah dicentang.
- EID harus dari device yang akan dipakai. QR eSIM yang terbit hanya
  bisa diaktifkan di HP yang EID-nya dimasukkan saat klaim.
- Tools ini cuma membungkus API publik yang sudah ada di web HYFE +
  `lpac` upstream untuk operasi eSIM lokal.

## Pengembangan

```sh
make lint    # shellcheck -s sh src/esim src/lib/*.sh
make test    # smoke: esim --help, esim --version
```

## Lisensi

MIT — lihat [LICENSE](LICENSE).
