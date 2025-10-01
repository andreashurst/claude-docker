# AI-Generated Git Commits

Automatische Commit-Message-Generierung mit Claude Sonnet 4.

## Setup

### Keine zusätzliche Konfiguration nötig!

Das Script nutzt die bereits laufende Claude Code Instanz im Container:

- ✅ Kein API Key erforderlich
- ✅ Keine zusätzlichen Kosten
- ✅ Nutzt bereits authentifizierte Session
- ✅ Script ist in `/var/www/html/bin/` und im `PATH`

## Usage

### Einfacher Commit

```bash
# Alle Änderungen stagen und committen
commit
```

### Mit Custom Message

```bash
# Zusätzlichen Kontext mitgeben
commit -m "Fixed critical security issue in authentication"
```

### Dry Run

```bash
# Commit-Message anzeigen ohne zu committen
commit -n
```

### Help

```bash
commit -h
```

## Features

### Was das Script macht

1. **Analysiert alle Änderungen**
   - Git status
   - Staged changes (diff --cached)
   - Unstaged changes (diff)
   - Recent commits (für Kontext)

2. **Generiert mit Claude Sonnet 4**
   - Folgt dem Format aus `commit.html`
   - Gruppiert Änderungen nach Kategorie
   - Listet alle geänderten Dateien
   - Erklärt WHAT und WHY (nicht HOW)
   - Auf Deutsch mit KISS-Prinzip

3. **Erstellt Commit**
   - Staget alle Änderungen (`git add -A`)
   - Erstellt Commit mit generierter Message
   - Speichert in `commit.html`
   - Fügt TRON-style ID hinzu

### Commit-ID Format

```
TRON-{ID}
```

**WICHTIG:** Die ID muss explizit gesetzt sein! Sie wird NICHT automatisch generiert.

Die ID wird ermittelt (in dieser Reihenfolge):

1. **Environment Variable** `TRON_ID` (höchste Priorität)
   ```bash
   export TRON_ID="1234"
   commit
   # → TRON-1234
   ```

2. **Branch Name** (extrahiert erste 4+ stellige Zahl)
   ```bash
   git checkout -b feature/5678-new-feature
   commit
   # → TRON-5678

   git checkout -b bugfix-9012
   commit
   # → TRON-9012

   git checkout -b TRON-3456-description
   commit
   # → TRON-3456
   ```

3. **`.claude/.tron-id` Datei** (persistent im Repo)
   ```bash
   mkdir -p .claude
   echo "1234" > .claude/.tron-id
   commit
   # → TRON-1234

   # Weitere Commits nutzen gleiche ID
   commit
   # → TRON-1234 (aus Datei gelesen)
   ```

4. **Interaktive Abfrage** wenn keine ID gefunden
   ```bash
   # Branch ohne Nummer:
   git checkout -b feature/my-feature
   commit

   # → ⚠️  No TRON-ID found
   #    Current branch: feature/my-feature
   #
   #    Please enter TRON-ID (e.g., 1234):
   #    > 5678
   #
   #    Save TRON-ID '5678' to .claude/.tron-id file for future commits? (y/n)
   #    > y
   #    ✓ Saved to .claude/.tron-id
   #
   #    → TRON-5678
   ```

### Commit Message Format

Folgt dem Format aus `commit.html`:

```markdown
# [Title] - YYYY-MM-DD

## Übersicht
[Brief overview in German]

## Hauptänderungen

### 1. [Category 1]
**Problem**: [Description]

**Lösung**:
- [Change 1]
- [Change 2]

### 2. [Category 2]
...

## Geänderte Dateien

1. `path/to/file`
   - [What changed]
   - [Why it changed]

## Vorteile

### Für Entwickler
- ✅ [Advantage 1]

### Für Claude Code
- ✅ [Advantage 1]

## Notizen
- [Additional notes]

---
Commit-ID: TRON-20250930-1430-A5F2
Generated: 2025-09-30 14:30:45
🤖 AI-Generated with Claude Sonnet 4
```

## Beispiele

### Standard Workflow

```bash
# Code ändern
vim src/app.js

# Commit mit KI
commit

# Review
git show

# Push
git push
```

### Mit Dry Run

```bash
# Änderungen machen
vim src/app.js
git add src/app.js

# Preview commit message
commit -n

# Wenn gut → wirklich committen
commit
```

### Mit Context

```bash
# Bei komplexen Änderungen zusätzlichen Kontext geben
commit -m "Refactored auth system to prepare for OAuth2 integration"
```

### Mit TRON ID

```bash
# Option 1: ENV Variable (für ganze Session)
export TRON_ID="8765"
commit  # → TRON-8765

# Option 2: Branch Name (automatisch)
git checkout -b feature/1234-login-fix
commit  # → TRON-1234 (aus Branch extrahiert)

# Option 3: Einmalig für einen Commit
TRON_ID="4321" commit  # → TRON-4321

# Option 4: .claude/.tron-id Datei (persistent)
mkdir -p .claude && echo "9999" > .claude/.tron-id
commit  # → TRON-9999
```

## Workflow Integration

### Pre-commit Hook

Wenn du das Script automatisch bei `git commit` ausführen willst:

```bash
# .git/hooks/prepare-commit-msg
#!/bin/bash
if [ -z "$2" ]; then
  # Nur wenn keine Message angegeben wurde
  /var/www/html/bin/git-commit-ai -n > "$1"
fi
```

### Alias in .gitconfig

```bash
git config --global alias.ai '!git-commit-ai'

# Usage:
git ai
git ai -n
git ai -m "context"
```

## Fehlerbehandlung

### Claude Code nicht erreichbar

```
Error: Failed to generate commit message
Is Claude Code running?
```

**Lösung**:
- Stelle sicher, dass du IM Container bist
- Claude Code sollte automatisch starten
- Falls nicht: `claude auth login`

### Keine Änderungen

```
No changes to commit
```

**Lösung**: Erst Dateien ändern

### Leere Commit Message

```
Error: Generated commit message is empty
```

**Lösung**: Claude Code neu starten oder manuell committen

## Kosten

**Keine zusätzlichen Kosten!** 🎉

- ✅ Nutzt bereits laufende Claude Code Session
- ✅ Keine API Calls
- ✅ Kostenlos innerhalb deines Claude Code Abos

## Best Practices

### DO ✅

1. **Review vor Push**
   ```bash
   commit        # AI generiert
   git show      # Review
   git push      # Wenn OK
   ```

2. **Custom Context bei komplexen Änderungen**
   ```bash
   commit -m "Breaking change: Renamed API endpoints for consistency"
   ```

3. **Dry Run bei Unsicherheit**
   ```bash
   commit -n     # Preview
   ```

4. **Logische Commits**
   - Ein Feature = Ein Commit
   - Kleine, fokussierte Änderungen
   - Nicht alles auf einmal

### DON'T ❌

1. **Nicht blind committen**
   ```bash
   # ❌ BAD:
   commit && git push

   # ✅ GOOD:
   commit
   git show
   git push
   ```

2. **Keine riesigen Commits**
   - 100+ Dateien → Aufteilen
   - Verschiedene Features → Separate Commits

3. **Nicht bei sensiblen Daten**
   - API Keys im Diff → Manuell committen
   - Passwörter → Nicht committen!

## Troubleshooting

### Script nicht gefunden

```bash
# Check PATH
echo $PATH | grep "/var/www/html/bin"

# Manuell hinzufügen
export PATH="/var/www/html/bin:$PATH"
```

### Permission Denied

```bash
chmod +x /var/www/html/bin/git-commit-ai
chmod +x /var/www/html/bin/commit
```

### Claude Command nicht im PATH

```bash
# PATH prüfen
which claude

# Manuell hinzufügen falls nötig
export PATH="/usr/local/bin:$PATH"
```

## Customization

### Claude Code CLI Optionen

Das Script nutzt `claude --no-input` für non-interactive Mode.

Weitere Optionen in `git-commit-ai` Zeile 189 anpassen.

### Anderes Format

Edit `git-commit-ai` Zeile 92-134 (PROMPT):

```bash
# Eigenes Format definieren
```

### Andere Sprache

Edit `git-commit-ai` Zeile 93:

```bash
# Statt German:
1. Use English for descriptions
```

## Security

- ✅ Nutzt lokale Claude Code Instanz (keine externen API Calls)
- ✅ Keine Daten verlassen den Container
- ✅ Keine Credentials in commit.html
- ✅ Git Diff bleibt lokal
- ✅ Sicher für alle Code-Typen

## Integration mit Claude Code

Das Script nutzt die laufende Claude Code Instanz:

1. **Direkte Integration**
   - Kein API Key nötig
   - Nutzt `claude` CLI Command
   - Non-interactive Mode (`--no-input`)

2. **Workflow**
   - Claude Code ändert Code
   - User ruft `commit` auf
   - Claude Code generiert Commit
   - User reviewed und pusht

3. **Vorteile**
   - Kostenlos (innerhalb Claude Code Abo)
   - Schnell (keine HTTP Requests)
   - Sicher (keine Daten verlassen Container)
   - Konsistent mit Projekt

## Links

- [Claude Code Docs](https://docs.claude.com/claude-code)
- [Git Commit Best Practices](https://cbea.ms/git-commit/)
- [Conventional Commits](https://www.conventionalcommits.org/)
