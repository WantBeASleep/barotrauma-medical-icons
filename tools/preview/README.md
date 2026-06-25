# Preview Tools

## Current Workflow

The active preview generator is the content showcase builder:

```powershell
python tools/preview/content_showcase/build_content_showcase.py
```

It writes the six current Workshop preview PNG files under `preview`:

- `01_textures.png`
- `02_medicine.png`
- `03_basic_chemicals.png`
- `04_toxins.png`
- `05_antidotes.png`
- `06_stimulants.png`

Run the project build with saved status icons before regenerating the showcase:

```powershell
python tools/build/build_project.py --save-status-icons
```

`preview/logo.gif` is kept as a curated asset for the Workshop package.
