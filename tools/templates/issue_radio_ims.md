# Radio/IMS Issue Template

## Symptom

## Repro

## Required artifacts
- `service list`
- `dumpsys telephony.registry`
- `dumpsys ims`
- `getprop | grep -Ei "ril|radio|ims|qcril"`
- `logcat -b radio -d`

## Must-have marker check
- `android.hardware.radio.*`
- `vendor.qti.hardware.radio.ims.*`
- `vendor.qti.ims.*`

## Candidate ownership fix
- source manifest/service vs blob rc/xml path:
