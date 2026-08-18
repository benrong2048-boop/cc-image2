---
name: cc-image2
description: "When the user wants to generate or edit images through CC Switch and gpt-image-2, especially when they say 'use image 2', 'use CC Switch to make an image', 'reference this image', 'keep the face/person/structure', 'change the background/hair/expression/clothes/style', or 'don't use the text model'. Use this for new image generation and reference-image editing. Always route to gpt-image-2, never the Codex built-in image_gen, and never fall back to another image model."
metadata:
  version: 1.0.0
---

# CC Image 2

Use this skill only through `scripts/generate.ps1`, which calls `gpt-image-2`. The script automatically chooses the right API route: generation when no reference image is provided, and image editing when `-ReferenceImage` is present.

## Mode Selection

| Task | Invocation | API |
| --- | --- | --- |
| Generate a new image from scratch | Do not pass `-ReferenceImage` | `images.generate` |
| Keep facial features, style, composition, or product traits and remake it | Pass one or more `-ReferenceImage` values | `images.edit` |
| Edit only part of an image | Pass a reference image and a PNG mask via `-Mask` | `images.edit` |

Do not replace an explicitly provided reference image with a pure text description. If the user says "like the original," "keep the face," or "reference this image," you must use reference-image mode.

## Generation Flow

1. Confirm `OPENAI_API_KEY` and `OPENAI_BASE_URL` are available. Do not display, record, or ask the user to paste secrets.
2. Decide whether a reference image is needed. If so, keep the original file path and pass it to `-ReferenceImage`. You may pass multiple reference images.
3. Write the prompt. State what to keep, what to change, and what to avoid. Do not rewrite the reference image contents as guessed text.
4. Choose the output file name and location. Default to `1536x2048` for portrait, `1536x1024` for landscape, and `1536x1536` for square.
5. Run the script, then verify the file exists and inspect the result with a local image viewer.

### Generate from Scratch

```powershell
& "$HOME/.codex/skills/cc-image2/scripts/generate.ps1" `
  -PromptFile "D:\prompt.txt" `
  -Out "D:\output\image.png" `
  -Size "1536x2048" `
  -Quality high
```

### Use One Reference Image

```powershell
& "$HOME/.codex/skills/cc-image2/scripts/generate.ps1" `
  -ReferenceImage "D:\input\portrait.jpg" `
  -PromptFile "D:\prompt.txt" `
  -Out "D:\output\portrait-variant.png" `
  -Size "1536x1536" `
  -Quality high
```

### Use Multiple Reference Images or a Mask

```powershell
& "$HOME/.codex/skills/cc-image2/scripts/generate.ps1" `
  -ReferenceImage "D:\input\face.jpg", "D:\input\style.png" `
  -Mask "D:\input\mask.png" `
  -PromptFile "D:\prompt.txt" `
  -Out "D:\output\edited.png" `
  -Size "1536x1536" `
  -Quality high
```

Use `-DryRun` to check paths and routing without actually calling the API:

```powershell
& "$HOME/.codex/skills/cc-image2/scripts/generate.ps1" `
  -ReferenceImage "D:\input\portrait.jpg" `
  -Prompt "Create a white-background child-photo-style avatar." `
  -Out "D:\output\check.png" `
  -Size "1536x1536" `
  -DryRun
```

## Prompt Boundaries

- Portraits: specify "keep visible facial proportions, hairline, skin tone, and age vibe," and clearly name the new expression, hairstyle, background, or style.
- Children's photos: use age-appropriate language such as children's album, birthday card, sticker, or illustration. For cropping the face, say "crop to a close-up portrait near the chin" to avoid unnecessary body or adult framing.
- Large amounts of Chinese text: let the image model handle the background, texture, and visual tone first, then overlay accurate text locally. Do not ask the image model to typeset long Chinese text character by character.
- Reference images help preserve similarity and material continuity, but every output must still be checked. Do not promise pixel-perfect replication.

## Constraints

- Always use `gpt-image-2` and pass `--no-augment`.
- Do not call the Codex built-in `image_gen`, and do not fall back to any other image model.
- Do not overwrite an existing output file automatically. If the file exists, choose a new versioned name.
- Do not output or echo API keys, endpoint URLs, or other credentials.
- `gpt-image-2` does not support transparent backgrounds. If transparency is required, explain that this skill is fixed to this model and ask the user to confirm whether another model is allowed.