# shellcheck shell=sh
# common.sh - shared helpers for hyfetrial
#
# Required globals (set by main script):
#   HYFE_VERBOSE   - "1" to enable verbose log
#   HYFE_DEBUG     - "1" to enable debug log (includes HTTP bodies)
#   HYFE_BASE      - upstream API base URL
#   HYFE_ORIGIN    - Origin/Referer URL for requests
#   HYFE_UA        - User-Agent string
#   HYFE_COOKIES   - path to cookie jar
#   HYFE_TOKEN     - bearer token (set after auth)
#   HYFE_CSRF      - csrf token (set after session)

: "${HYFE_VERBOSE:=0}"
: "${HYFE_DEBUG:=0}"
: "${HYFE_BASE:=https://jupiter-ms-webprio-v2.ext.dp.xl.co.id}"
: "${HYFE_AUTH_URL:=https://prioritas.xl.co.id/hyfe-apply/api/auth}"
: "${HYFE_ORIGIN:=https://prioritas.xl.co.id}"
: "${HYFE_REFERER:=https://prioritas.xl.co.id/hyfe-apply/esim-trial}"
: "${HYFE_UA:=Mozilla/5.0 (Linux; OpenWrt) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36}"
: "${HYFE_RECAPTCHA_SITEKEY:=6Lf-vXwiAAAAABOLVRxiP3pWHhgs8g7KFJUXhb6i}"
: "${HYFE_RECAPTCHA_PAGE_URL:=https://prioritas.xl.co.id/hyfe-apply/esim-trial/input-eid}"
: "${HYFE_TNC_CHANNEL_ID:=7c93208a-6a17-462d-933b-73492818ce01}"

log_info() {
    printf '[hyfetrial] %s\n' "$*" >&2
}

log_warn() {
    printf '[hyfetrial][warn] %s\n' "$*" >&2
}

log_error() {
    printf '[hyfetrial][error] %s\n' "$*" >&2
}

log_verbose() {
    [ "$HYFE_VERBOSE" = "1" ] || [ "$HYFE_DEBUG" = "1" ] || return 0
    printf '[hyfetrial][verbose] %s\n' "$*" >&2
}

log_debug() {
    [ "$HYFE_DEBUG" = "1" ] || return 0
    printf '[hyfetrial][debug] %s\n' "$*" >&2
}

die() {
    log_error "$@"
    exit 1
}

# Require external commands
require_cmd() {
    for cmd in "$@"; do
        command -v "$cmd" >/dev/null 2>&1 || die "command not found: $cmd"
    done
}

# Generate a UUID-v4 like string (for requestid header).
# Uses /proc/sys/kernel/random/uuid if available (Linux),
# otherwise falls back to /dev/urandom + awk.
gen_uuid() {
    if [ -r /proc/sys/kernel/random/uuid ]; then
        cat /proc/sys/kernel/random/uuid
        return
    fi
    if command -v uuidgen >/dev/null 2>&1; then
        uuidgen
        return
    fi
    # POSIX fallback
    od -An -N16 -tx1 /dev/urandom 2>/dev/null \
        | tr -d ' \n' \
        | awk '{
            printf "%s-%s-4%s-%s%s-%s\n",
                substr($0,1,8), substr($0,9,4),
                substr($0,14,3),
                substr(substr($0,17,1),1,1)~/[89ab]/?substr($0,17,1):"a",
                substr($0,18,3), substr($0,21,12)
        }'
}

# JSON-escape a string (for embedding in JSON payloads when jq is not desired).
json_escape() {
    # Read from $1 (or stdin if missing)
    if [ $# -gt 0 ]; then
        printf '%s' "$1" | jq -Rs .
    else
        jq -Rs .
    fi
}

# Pretty-print JSON to stderr if debug is on
debug_json() {
    [ "$HYFE_DEBUG" = "1" ] || return 0
    label="$1"
    shift
    printf '[hyfetrial][debug] %s:\n' "$label" >&2
    if [ $# -gt 0 ]; then
        printf '%s\n' "$1" | jq . >&2 2>/dev/null \
            || printf '%s\n' "$1" >&2
    else
        jq . >&2 2>/dev/null
    fi
}

# Validate that a JSON response from the upstream succeeded.
# Usage: assert_status_ok "<context>" "<json_body>"
assert_status_ok() {
    ctx="$1"
    body="$2"
    sc=$(printf '%s' "$body" | jq -r '.statusCode // empty' 2>/dev/null)
    if [ -z "$sc" ]; then
        log_error "$ctx: no statusCode in response"
        log_error "body: $body"
        return 1
    fi
    if [ "$sc" != "200" ] && [ "$sc" != "201" ]; then
        msg=$(printf '%s' "$body" | jq -r '.statusMessage // .message // .result.errorMessage // "unknown"' 2>/dev/null)
        log_error "$ctx: statusCode=$sc message=$msg"
        log_error "body: $body"
        return 1
    fi
    return 0
}

# Read cookie value from cookie jar.
# Usage: cookie_get <name>
#
# curl writes Netscape-format cookies. Comment lines start with `# `.
# HttpOnly cookies are written as `#HttpOnly_<domain>\t...` (no space, leading
# `#` is significant). We must include those - the auth `token` cookie set by
# /hyfe-apply/api/auth is HttpOnly - while still excluding real `# Netscape...`
# header/comment lines.
cookie_get() {
    name="$1"
    [ -f "$HYFE_COOKIES" ] || return 1
    awk -v n="$name" '
        # skip blank lines and comments that are NOT "#HttpOnly_..."
        /^[[:space:]]*$/ { next }
        /^#/ && $0 !~ /^#HttpOnly_/ { next }
        # for HttpOnly lines the domain field still has the "#HttpOnly_" prefix,
        # but field positions are unchanged, so $6 is still the cookie name.
        $6 == n { print $7; exit }
    ' "$HYFE_COOKIES"
}

# Helper: trim leading/trailing whitespace
trim() {
    printf '%s' "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}
