# DivineDominion

Real-time strategy game prototype inspired by Mega-Lo-Mania (1991), built with Godot 4.6 and GDScript.

## Play

Download the latest Windows build from the [Releases page](https://github.com/psylector/divine-dominion/releases). No installation needed — just run `DivineDominion.exe`.

## Development

### Prerequisites

- **Godot 4.6.2+** — [godotengine.org/download](https://godotengine.org/download)
- **Python 3.10+** — for code quality tools
- **GitHub CLI** — [cli.github.com](https://cli.github.com)

### Getting Started

```bash
git clone git@github.com:psylector/divine-dominion.git
cd divine-dominion
pip install pre-commit gdtoolkit==4.3.4
pre-commit install
```

Open the project in Godot editor and run `scenes/main/main.tscn`.

### Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full workflow.

**TL;DR:** Create a feature branch, push a PR. CI + CodeRabbit must pass — then auto-merge and rolling release happen automatically.
