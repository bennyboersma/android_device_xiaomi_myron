# Audio Issue Template

## Symptom

## Repro path
- speaker / earpiece / wired / bluetooth

## Required artifacts
- `dumpsys media.audio_policy`
- `dumpsys media.audio_flinger`
- `logcat -b all -d | grep -Ei "audio|pal|agm|sthal"`

## Candidate ownership fix
- audio HAL service + policy/config ownership:
