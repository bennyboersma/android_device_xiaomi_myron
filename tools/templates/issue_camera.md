# Camera Issue Template

## Symptom

## Repro

## Required artifacts
- `service list`
- `dumpsys media.camera`
- `logcat -b all -d | grep -Ei "camera|camx|mivi|provider"`

## Must-have marker check
- `android.hardware.camera.provider.ICameraProvider/vendor_qti/0`

## Candidate ownership fix
- provider init rc / VINTF fragment ownership:
