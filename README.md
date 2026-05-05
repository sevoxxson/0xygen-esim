# 0xygen-esim (`hyfetrial`)

CLI ringan untuk klaim **eSIM Trial HYFE** (XL Prioritas) dari OpenWrt
maupun Linux biasa. Murni `sh` + `curl` + `jq`, tanpa kompilasi.

Mengotomatiskan flow web di
<https://prioritas.xl.co.id/hyfe-apply/esim-trial>:

1. Pilih nomor (acak, atau cari pakai pola digit favorit)
2. Isi data (nama, WhatsApp, email)
3. Isi EID (32 digit)
4. Verifikasi email lewat OTP + reCAPTCHA Enterprise
5. Submit dan dapatkan eSIM trial

[![build](https://github.com/nyawitniorang/0xygen-esim/actions/workflows/build.yml/badge.svg)](https://github.com/nyawitniorang/0xygen-esim/actions/workflows/build.yml)

## Struktur repo

```
.
├── src/
│   ├── hyfetrial         # entrypoint CLI
│   └── lib/
│       ├── common.sh     # logging, helpers, cookie jar
│       ├── api.sh        # wrapper endpoint upstream HYFE
│       ├── captcha.sh    # solver reCAPTCHA (manual / 2captcha / ...)
│       └── otp.sh        # OTP loader (manual / IMAP)
├── etc/config.example    # contoh config (di-source dengan --config)
├── openwrt/hyfetrial/    # paket OpenWrt (Makefile, opkg/apk)
├── .github/workflows/    # CI: shellcheck + build .ipk + .apk
├── Makefile              # install/uninstall generik (POSIX)
├── LICENSE
└── README.md
```

## Quick start (interaktif)

```sh
hyfetrial
```

Tanpa flag apapun, CLI akan tanya satu per satu. Untuk Nama dan
Nomor WhatsApp, hyfetrial menawarkan pilihan **1) random** atau
**2) ketik manual** (Enter = pilihan 1):

```
=== hyfetrial: mode interaktif ===
Nama lengkap
  1) random
  2) ketik manual
Pilih [1]:
[hyfetrial] nama random: Andi Pratama
Nomor WhatsApp
  1) random
  2) ketik manual
Pilih [1]: 2
Nomor WhatsApp (tanpa +62/0): 81234567890
Email (yang akan menerima OTP): saya@gmail.com

EID HARUS dari device yang akan dipakai untuk eSIM ini.
  - Cek di iPhone:  Settings > General > About > EID
  - Cek di Android: Settings > About phone > SIM status > EID
  - Random/EID milik device lain = QR eSIM tidak bisa diaktifkan.

EID eSIM (32 digit): 12345678901234567890123456789012
Pola digit nomor cantik (kosongkan untuk random): 8888
Mode captcha: manual / 2captcha / anticaptcha / capsolver / nextcaptcha [manual]:
Mode OTP: manual / imap [manual]:
```

**Catatan EID**: tidak ada opsi random untuk EID. EID adalah identitas
unik device — QR eSIM yang terbit hanya bisa diaktifkan di HP yang
EID-nya dimasukkan saat klaim. Memakai EID milik device lain berarti
hasilnya tidak bisa diaktifkan.

**Catatan WhatsApp random**: nomor random tidak akan menerima
notifikasi/OTP WA. Pakai ini hanya kalau Anda yakin pipeline klaim
tidak butuh konfirmasi via WhatsApp.

Atau lewat flag (non-interaktif, bagus untuk script):

```sh
hyfetrial --name "Andi Pratama" --whatsapp 81234567890 \
          --email saya@gmail.com \
          --eid 12345678901234567890123456789012 \
          --pattern 8888 --yes
```

Pakai `hyfetrial --help` untuk daftar opsi lengkap.

## Install

### OpenWrt — paket pre-built dari GitHub Releases

Setiap tag `v*` memicu workflow yang melampirkan `.ipk` (untuk OpenWrt 24.10)
dan `.apk` (untuk OpenWrt 25 / SNAPSHOT) ke
<https://github.com/nyawitniorang/0xygen-esim/releases>.

**OpenWrt 24.10 (opkg, `.ipk`):**

```sh
opkg update
opkg install curl jq ca-bundle
wget https://github.com/nyawitniorang/0xygen-esim/releases/latest/download/hyfetrial_0.1.0-1_all.ipk
opkg install ./hyfetrial_*_all.ipk
```

**OpenWrt 25 SNAPSHOT (apk, `.apk`):**

```sh
apk update
apk add curl jq ca-bundles
wget https://github.com/nyawitniorang/0xygen-esim/releases/latest/download/hyfetrial-0.1.0-r1.apk
apk add --allow-untrusted ./hyfetrial-*.apk
```

(Nama file persisnya akan ada di halaman release - copy dari sana.)

### Build dari source (OpenWrt SDK)

Lihat komentar di `openwrt/hyfetrial/Makefile` untuk command lengkap.
Singkatnya:

```sh
# di repo ini
cd /tmp
wget https://downloads.openwrt.org/releases/24.10.0/targets/x86/64/openwrt-sdk-24.10.0-x86-64_*.tar.zst
tar xf openwrt-sdk-*.tar.zst
cd openwrt-sdk-24.10.0-*
echo "src-link hyfetrial $(realpath ../0xygen-esim)" >> feeds.conf
./scripts/feeds update hyfetrial
./scripts/feeds install hyfetrial
make defconfig
make package/hyfetrial/compile V=s
find bin/ -name 'hyfetrial*'
```

### Linux biasa (POSIX `make install`)

```sh
git clone https://github.com/nyawitniorang/0xygen-esim.git
cd 0xygen-esim
sudo make install                 # ke /usr/local
# atau
sudo make install PREFIX=/usr     # ke /usr
```

Pastikan `curl` dan `jq` terpasang.

### Tanpa install (run dari folder repo)

```sh
./src/hyfetrial --help
./src/hyfetrial                    # interaktif
```

`hyfetrial` otomatis menemukan folder `lib/` di sebelah binary-nya.

## Captcha modes

| Mode          | Cara kerja                                         | Biaya    |
| ------------- | -------------------------------------------------- | -------- |
| `manual`      | Paste token `grecaptcha.getResponse()` (default)   | gratis   |
| `2captcha`    | Solve via API <https://2captcha.com/>              | min $1 (~Rp16K), $1-2.99/1000 |
| `anticaptcha` | Solve via API <https://anti-captcha.com/>          | min $5, ~$2/1000 |
| `capsolver`   | Solve via API <https://capsolver.com/>             | min $5, $1/1000 |
| `nextcaptcha` | Solve via API <https://nextcaptcha.com/>           | **free trial** via Telegram bot [@nextcaptcha_free_trial_bot](https://t.me/nextcaptcha_free_trial_bot), then $0.6/1000 |

Contoh dengan 2captcha:

```sh
hyfetrial --captcha-mode 2captcha --captcha-key YOUR_KEY \
          --name "..." --whatsapp ... --email ... --eid ...
```

## OTP modes

| Mode      | Cara kerja                                                       |
| --------- | ---------------------------------------------------------------- |
| `manual`  | Ketik OTP 6 karakter di terminal (default)                       |
| `imap`    | Polling IMAP via curl, auto-ambil OTP dari email terbaru         |

Contoh IMAP (Gmail App Password):

```sh
hyfetrial --otp-mode imap \
          --imap-url imaps://imap.gmail.com:993 \
          --imap-user me@gmail.com \
          --imap-pass YOUR_APP_PASSWORD \
          --name "..." --whatsapp ... --email me@gmail.com --eid ...
```

OpenWrt note: `imap` mode requires curl/libcurl with IMAP enabled. Check with:

```sh
curl -V
```

The `Protocols:` line must contain `imap imaps`. Some OpenWrt 25/APK firmware
builds ship curl without those protocols and will fail with:

```text
curl: (1) Protocol "imaps" disabled
```

For those images, either use `--otp-mode manual` or rebuild/install curl/libcurl
with OpenWrt config `CONFIG_LIBCURL_IMAP=y` before using IMAP OTP automation.

## Config file

Daripada mengulang flag panjang, simpan setting captcha/IMAP/email di
`/etc/hyfetrial/config`. File itu **otomatis dibaca** kalau ada — tidak
perlu lagi `--config /etc/hyfetrial/config` di setiap pemanggilan.

```sh
hyfetrial --new-config        # wizard pertama kali / partial edit
hyfetrial --captcha-config    # update mode + API key captcha saja
hyfetrial --imap-config       # update server IMAP saja
hyfetrial --email-config      # tambah/hapus akun email + App Password
hyfetrial --config            # lihat config aktif (password ter-mask)
hyfetrial                     # langsung jalan dengan config tersimpan
```

### Multi-akun email

Daftarkan beberapa Gmail sebagai pasangan `HYFE_EMAIL_N` +
`HYFE_IMAP_PASS_N`:

```sh
HYFE_EMAIL_1=saya@gmail.com
HYFE_IMAP_PASS_1="aaaa bbbb cccc dddd"

HYFE_EMAIL_2=akun.kedua@gmail.com
HYFE_IMAP_PASS_2="eeee ffff gggg hhhh"
```

Saat prompt interaktif, hyfetrial menampilkan menu:

```
Email:
  1) saya@gmail.com
  2) akun.kedua@gmail.com
  3) ketik manual
Pilih [1]:
```

Pilih akun N → email + IMAP App Password ikut dipakai otomatis.

### Multi-EID

Saved EIDs disimpan sebagai `HYFE_EID_1`, `HYFE_EID_2`, ... Saat prompt
interaktif untuk EID, hyfetrial menampilkan:

```
EID:
  1) 89049032007208882600178661005175
  2) 89049032007208882600178661005200
  3) edit 3 digit terakhir
  4) ketik manual EID baru
Pilih [1]:
```

Opsi "edit 3 digit terakhir" prefill prefix dari saved EID dan hanya
meminta tail baru — berguna kalau Anda klaim banyak eSIM dengan EID
sequential. Opsi "ketik manual" akan menawarkan auto-save.

### Per-provider captcha key

Sejak r13, key API setiap captcha solver punya slot tersendiri jadi
ganti mode tidak menghapus key provider lain:

```sh
HYFE_CAPTCHA_MODE=nextcaptcha
HYFE_CAPTCHA_KEY_NEXTCAPTCHA=next_xxxxxxxxxx
HYFE_CAPTCHA_KEY_2CAPTCHA=2c_yyyyyyy
HYFE_CAPTCHA_KEY_ANTICAPTCHA=
HYFE_CAPTCHA_KEY_CAPSOLVER=
```

`hyfetrial --captcha-config` memilih mode + key untuk mode yang dipilih.
Config lama dengan `HYFE_CAPTCHA_KEY=...` (tanpa suffix) akan di-migrasi
otomatis ke slot yang sesuai pada wizard berikutnya.

### First-run bootstrap

Kalau `/etc/hyfetrial/config` belum ada saat `hyfetrial` dijalankan
secara interaktif, hyfetrial menawarkan setup wizard sebelum claim flow
mulai. Pilih `Y` untuk setup sekali, lalu run-run berikutnya tinggal
`hyfetrial`.

CLI flag selalu menang atas nilai di config file. Override file lain via
`--config /path/lain` atau `HYFE_DEFAULT_CONFIG=/path/lain`.

## Endpoint yang dipakai

```
POST  prioritas.xl.co.id/hyfe-apply/api/auth     -> set cookie "token"
GET   /hyfe/v1/session                           -> csrfToken
POST  /hyfe/v1/msisdn/findResources?page=N       -> daftar nomor + encrypt
POST  /comet/v1/tnc/tncToken                     -> access_token (Keycloak)
POST  /comet/v1/tnc/optIn                        -> consentId (Auth: raw token)
POST  /hyfe/v1/esim/freeTrial/send-otp           -> kirim OTP email
POST  /hyfe/v1/esim/freeTrial/validateAndSubmit  -> submit final + reCAPTCHA
```

Base API: `https://jupiter-ms-webprio-v2.ext.dp.xl.co.id`.

## Catatan / batasan

- reCAPTCHA Enterprise tidak bisa di-bypass; solver berbayar atau paste manual
  adalah satu-satunya jalur yang stabil.
- Token reCAPTCHA hanya valid ~2 menit setelah dicentang. Kalau lewat,
  ulang langkah captcha di mode manual.
- Default User-Agent menyamarkan diri sebagai Chrome desktop dari OpenWrt.
  Override pakai `--user-agent`.
- Tools ini hanya membungkus API publik yang sudah ada di web HYFE, tidak
  melakukan privilege escalation atau bypass autentikasi.

## Pengembangan

```sh
make lint    # shellcheck -s sh src/...
make test    # smoke: --help, --list-numbers
```

## Lisensi

MIT — lihat [LICENSE](LICENSE).
