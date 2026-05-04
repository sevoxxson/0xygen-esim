# shellcheck shell=sh
# otp.sh - obtain the OTP code emailed by HYFE.
#
# Modes:
#   manual  - prompt the user to type the code (default)
#   imap    - poll an IMAP mailbox via curl, scrape the OTP code from
#             the most recent matching message.
#
# Required env for IMAP mode:
#   HYFE_IMAP_URL   - e.g. imaps://imap.gmail.com:993
#   HYFE_IMAP_USER  - mailbox login
#   HYFE_IMAP_PASS  - mailbox password / app password
#   HYFE_IMAP_FOLDER (optional, default INBOX)
#   HYFE_IMAP_SUBJECT (optional, default "Kode OTP | eSIM Trial HYFE")
#   HYFE_IMAP_TIMEOUT (optional, default 120)
#
# Usage:
#   code=$(otp_get) || exit 1

: "${HYFE_OTP_MODE:=manual}"
: "${HYFE_IMAP_FOLDER:=INBOX}"
: "${HYFE_IMAP_SUBJECT:=Kode OTP | eSIM Trial HYFE}"
: "${HYFE_IMAP_TIMEOUT:=180}"

otp_get() {
    case "$HYFE_OTP_MODE" in
        manual) _otp_manual ;;
        imap)   _otp_imap ;;
        *)      log_error "unknown otp mode: $HYFE_OTP_MODE"; return 1 ;;
    esac
}

_otp_manual() {
    {
        printf '\n'
        printf '  Cek email Anda untuk kode OTP dari HYFE.\n'
        printf '  Subject: "%s"\n' "$HYFE_IMAP_SUBJECT"
        printf '\n'
        printf '  Masukkan kode OTP, lalu Enter:\n'
    } >&2
    printf '> ' >&2
    IFS= read -r code
    code=$(trim "$code")
    [ -n "$code" ] || { log_error "no OTP entered"; return 1; }
    printf '%s' "$code"
}

# Poll an IMAP mailbox via curl. The OTP email currently contains a 6-char
# code (historically digits-only, now alphanumeric like UWHQZT). We grep the
# first likely token from the latest matching message.
_otp_imap() {
    [ -n "${HYFE_IMAP_URL:-}" ]  || { log_error "imap: HYFE_IMAP_URL required"; return 1; }
    [ -n "${HYFE_IMAP_USER:-}" ] || { log_error "imap: HYFE_IMAP_USER required"; return 1; }
    [ -n "${HYFE_IMAP_PASS:-}" ] || { log_error "imap: HYFE_IMAP_PASS required"; return 1; }

    log_info "imap: polling $HYFE_IMAP_URL/$HYFE_IMAP_FOLDER for OTP (timeout ${HYFE_IMAP_TIMEOUT}s)"
    elapsed=0
    base="$HYFE_IMAP_URL"
    folder=$(printf '%s' "$HYFE_IMAP_FOLDER" | sed 's/ /%20/g')
    auth_user="$HYFE_IMAP_USER"
    auth_pass="$HYFE_IMAP_PASS"

    while [ "$elapsed" -lt "$HYFE_IMAP_TIMEOUT" ]; do
        # IMAP SEARCH for unseen + matching subject. RFC 3501 SEARCH is supported
        # by curl --request 'SEARCH ...'.
        search_resp=$(curl -s --max-time 30 \
            --user "$auth_user:$auth_pass" \
            --request "SEARCH UNSEEN SUBJECT \"$HYFE_IMAP_SUBJECT\"" \
            "$base/$folder" 2>/dev/null) || true
        # Response looks like: "* SEARCH 12 13 14"
        ids=$(printf '%s' "$search_resp" | awk '/\* SEARCH/{for (i=3;i<=NF;i++) print $i}')
        if [ -n "$ids" ]; then
            # Take the highest UID (most recent)
            uid=$(printf '%s\n' "$ids" | tail -n1)
            log_verbose "imap: candidate uid=$uid"
            body=$(curl -s --max-time 30 \
                --user "$auth_user:$auth_pass" \
                --url "$base/$folder;UID=$uid" 2>/dev/null) || true
            if [ -n "$body" ]; then
                code=$(_otp_extract "$body")
                if [ -n "$code" ]; then
                    log_info "imap: extracted OTP code"
                    printf '%s' "$code"
                    return 0
                fi
            fi
        fi
        sleep 5
        elapsed=$((elapsed + 5))
    done
    log_error "imap: timeout, no matching email"
    return 1
}

# Extract a HYFE OTP from raw RFC822 message text. We try the most specific
# patterns first (label "OTP" / "kode" / "code" near the token), then fall
# back to any standalone 6-char uppercase/digit token.
_otp_extract() {
    raw="$1"
    # Strip MIME boundaries / decode quoted-printable enough for ASCII OTPs.
    text=$(printf '%s' "$raw" \
        | tr -d '\r' \
        | sed -e 's/=3D/=/g' -e 's/=20/ /g' -e 's/=2E/./g')

    # Pattern 1: token adjacent to "OTP" / "kode" / "code"
    code=$(printf '%s' "$text" | grep -oE -i '(otp|kode|code)[^A-Z0-9]{0,40}[A-Z0-9]{6}' \
        | head -n1 | grep -oE '[A-Z0-9]{6}' | head -n1)
    [ -n "$code" ] && { printf '%s' "$code"; return 0; }

    # Pattern 2: token after a colon, common in current HYFE email template
    code=$(printf '%s' "$text" | grep -oE ':[[:space:]]*[A-Z0-9]{6}\b' \
        | head -n1 | grep -oE '[A-Z0-9]{6}' | head -n1)
    [ -n "$code" ] && { printf '%s' "$code"; return 0; }

    # Pattern 3: any standalone 6-char uppercase/digit token
    code=$(printf '%s' "$text" | grep -oE '\b[A-Z0-9]{6}\b' | head -n1)
    [ -n "$code" ] && { printf '%s' "$code"; return 0; }

    return 1
}
