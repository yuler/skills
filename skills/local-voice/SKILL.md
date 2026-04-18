---
name: local-voice
description: Generates speech locally with OmniVoice via explore-tts. Supports voice cloning, voice design, and offline synthesis. Use for local TTS and WAV output.
---

# Local voice (explore-tts)

## When to use

Use this skill whenever speech must be **generated on the machine** using the **explore-tts** checkout and **`omni-voice-cli.sh`**. Do not substitute another TTS tool unless the user explicitly asks.

## Default mode (no special instruction)

**Use voice cloning** with a **default reference clip** the user keeps on disk (substitute the real path for the placeholder):

`--ref-audio "<PATH_TO_REFERENCE_AUDIO>"`

Unless the user clearly asks for something else (random voice, a different `--ref-audio`, or `--instruct` voice design), **always** pass this flag.

## Workflow

1. **Working directory**: `cd` to the explore-tts project root:

   `<PATH_TO_EXPLORE_TTS>`

2. **Run the CLI** from that directory. **Typical invocation (default clone):**

   ```bash
   mkdir -p ./dist
   ./omni-voice-cli.sh --text '…' --output './dist/output.wav' --ref-audio "<PATH_TO_REFERENCE_AUDIO>"
   ```

3. **Ensure the output directory exists** when it is not `./dist` or when skipping `mkdir` in a one-off command.

## CLI options (`omni-voice-cli.sh`)

| Flag | Argument | Meaning |
|------|-----------|---------|
| `--text` | `TEXT` | Text to synthesize (**required**). |
| `--output` | `FILE` | Output audio file. Default: `output.wav`. |
| `--ref-audio` | `FILE` | Reference audio for voice cloning. |
| `--ref-text` | `TEXT` | Reference audio transcript (cloning). |
| `--instruct` | `TEXT` | Voice design string: comma-separated attributes, **one value per category**; optional mix of English and Chinese tokens. See **Instruct categories** below. |
| `--language` | `LANG` | Language for voice design (e.g. `English`). |
| `--num-step` | `N` | Number of steps. Default: `32`. |
| `--guidance-scale` | `N` | Guidance scale. Default: `2.0`. |
| `--speed` | `N` | Speaking speed: `>1` faster, `<1` slower; omit for model default. |

**Instruct categories** (for `--instruct`; pick at most one token per line where applicable, join with commas):

- **gender**: `male`, `female`
- **age**: `child`, `teenager`, `young adult`, `middle-aged`, `elderly`
- **pitch**: `very low pitch`, `low pitch`, `moderate pitch`, `high pitch`, `very high pitch`
- **style**: `whisper`
- **English accent** (when synthesized text is English): `american`, `british`, `australian`, `canadian`, `indian`, `chinese`, `korean`, `japanese`, `portuguese`, `russian accent`
- **Chinese dialect** (when synthesized text is Chinese): `河南话`, `陕西话`, `四川话`, `贵州话`, `云南话`, `桂林话`, `济南话`, `石家庄话`, `甘肃话`, `宁夏话`, `青岛话`, `东北话`

Combine flags as needed: cloning uses `--ref-audio` (and optionally `--ref-text`); voice design uses `--instruct` and `--language` together. `--speed` is optional for any run when the user wants tempo control.

## Other modes (only when the user asks)

| Mode | When | Flags |
|------|------|--------|
| Clone (default) | No special TTS instruction | `--ref-audio "<PATH_TO_REFERENCE_AUDIO>"` (optional `--ref-text` if user supplies transcript) |
| Random voice | User wants default/random voice, no cloning | `--text` and `--output` only |
| Custom clone | User names another reference file | `--ref-audio PATH` (and `--ref-text` if needed) |
| Voice design | User wants described voice | `--instruct '…'` and `--language LANG` (e.g. `English`) |

For defaults and semantics of each flag, see **CLI options** above.

## Examples

**Default (clone from reference audio):**

```bash
cd <PATH_TO_EXPLORE_TTS>
mkdir -p ./dist
./omni-voice-cli.sh --text "Hello, this is a test." --output "./dist/output-1.wav" --ref-audio "<PATH_TO_REFERENCE_AUDIO>"
```

**Long text (heredoc; still default clone):**

```bash
cd <PATH_TO_EXPLORE_TTS>
mkdir -p ./dist
TEXT=$(cat <<'EOF'
Your multi-line script here.
EOF
)
./omni-voice-cli.sh --text "$TEXT" --output "./dist/output-1.wav" --ref-audio "<PATH_TO_REFERENCE_AUDIO>"
```

**Random voice (user explicitly does not want cloning):**

```bash
cd <PATH_TO_EXPLORE_TTS>
mkdir -p ./dist
./omni-voice-cli.sh --text "Hello, this is a test." --output "./dist/output-1.wav"
```

**Voice design:**

```bash
cd <PATH_TO_EXPLORE_TTS>
mkdir -p ./dist
./omni-voice-cli.sh --text 'Hello' --instruct 'male, british' --language English --output "./dist/design.wav"
```

## Reference

For project-specific notes and samples, read `<PATH_TO_EXPLORE_TTS>/README.md` when details differ from this skill.
