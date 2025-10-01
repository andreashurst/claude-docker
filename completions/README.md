# Shell Completions

Tab completion for Claude Docker commands.

## Installation

### Bash

```bash
# Copy to bash completion directory
sudo cp completions/claude-dev.bash /etc/bash_completion.d/
sudo cp completions/claude-flow.bash /etc/bash_completion.d/

# Reload
source /etc/bash_completion
```

Or add to your `~/.bashrc`:
```bash
source /path/to/claude-docker/completions/claude-dev.bash
source /path/to/claude-docker/completions/claude-flow.bash
```

### Zsh

```bash
# Copy to zsh completion directory
sudo cp completions/_claude-dev /usr/local/share/zsh/site-functions/
sudo cp completions/_claude-flow /usr/local/share/zsh/site-functions/

# Reload
compinit
```

Or add to your `~/.zshrc`:
```bash
fpath=(/path/to/claude-docker/completions $fpath)
autoload -Uz compinit && compinit
```

## Usage

After installation, you can use tab completion:

```bash
claude-dev --<TAB>
# Shows: --version --stop --clean --root --help

claude-flow --<TAB>
# Shows: --version --stop --clean --root --help
```

## Testing

Test completions without installation:

**Bash:**
```bash
source completions/claude-dev.bash
claude-dev --<TAB>
```

**Zsh:**
```bash
fpath=(completions $fpath)
autoload -Uz compinit && compinit
claude-dev --<TAB>
```
