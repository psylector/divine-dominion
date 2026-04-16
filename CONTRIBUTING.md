## Development Setup

### Prerequisites

- **Godot 4.6.2+** — [godotengine.org/download](https://godotengine.org/download)
- **Python 3.10+** — for code quality tools
- **GitHub CLI** — [cli.github.com](https://cli.github.com)

### One-time setup

```bash
git clone git@github.com:psylector/divine-dominion.git
cd divine-dominion
pip install pre-commit gdtoolkit==4.3.4
pre-commit install
```

## Making Changes

Direct push to main is blocked. All changes go through Pull Requests.

```bash
git checkout -b feature/my-change
# ... make changes ...
gdlint scripts/ scenes/
gdformat scripts/ scenes/
git add . && git commit -m "Description"
git push -u origin feature/my-change
gh pr create --fill
```

### What happens after you push a PR:

1. **GitHub Actions CI** runs `gdlint`, `gdformat --check`, and Godot project validation
2. **CodeRabbit** performs AI-based code review
3. If both pass with no findings — **auto-merge** into main
4. On merge — **rolling release** builds and publishes a new Windows binary

### If CodeRabbit finds issues:

- Fix the findings and push again
- Previous approval is dismissed on new push (stale review protection)
- All review threads must be resolved before merge

### Running checks locally

```bash
gdlint scripts/ scenes/           # style + complexity
gdformat --check scripts/ scenes/  # formatting check
gdformat scripts/ scenes/          # auto-fix formatting
pre-commit run --all-files          # run all hooks
```
