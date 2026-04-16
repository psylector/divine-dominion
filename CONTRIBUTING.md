## Development Setup

### Pre-commit hooks

This project uses `pre-commit` to run linters and formatters before each commit.

**One-time setup:**

```bash
pip install pre-commit
pre-commit install
```

After this, `gdlint` and `gdformat` will run automatically before every commit.

**Manual run on all files:**

```bash
pre-commit run --all-files
```

### Running gdlint/gdformat manually

```bash
pip install gdtoolkit==4.3.4
gdlint scripts/ scenes/
gdformat scripts/ scenes/  # auto-format
```
