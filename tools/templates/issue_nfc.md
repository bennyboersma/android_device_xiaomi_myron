# NFC Issue Template

## Symptom

## Repro

## Required artifacts
- `service list`
- `dumpsys nfc`
- `firstboot.nfc_props.txt`
- `firstboot.nfc_log_grep.txt`
- `firstboot.dev_nfc.txt`
- `firstboot.lsmod_nfc.txt`

## Must-have marker check
- `android.hardware.nfc.INfc/default`

## Candidate ownership fix
- framework NFC app/apex start path
- init ownership for NFC HAL service
- SELinux only if it directly blocks HAL registration
