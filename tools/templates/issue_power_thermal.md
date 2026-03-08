# Power/Thermal Issue Template

## Symptom

## Required artifacts
- `dumpsys power`
- `dumpsys thermalservice`
- `dumpsys battery`
- `logcat -b all -d | grep -Ei "thermal|power|health"`

## Must-have marker check
- `android.hardware.power.*`
- `android.hardware.health.*`

## Candidate ownership fix
- power/health service rc + VINTF ownership:
