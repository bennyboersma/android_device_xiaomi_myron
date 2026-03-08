# Decryption / Data Mount Issue Template

## Symptom
- device reaches boot UI or recovery path but `/data` does not mount correctly

## Required artifacts
- `firstboot.mount.txt`
- `firstboot.critical_log_grep.txt`
- `firstboot.key_props.txt`
- `logcat -b all -d | grep -Ei "vold|fscrypt|userdata|metadata|checkpoint"`

## Required checks
- `/data` mount state
- metadata mount state
- `sys.boot_completed`
- whether recovery or rescue path was entered

## Candidate fix areas
- vold / fscrypt path
- metadata partition assumptions
- keymint / gatekeeper / tee path
- userdata checkpoint behavior
