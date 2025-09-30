# MCP Strukturverbesserungen - 2025-09-30

## Übersicht
Alle MCP (Model Context Protocol) Dateien wurden vereinheitlicht und für Claude Code optimiert.

## Hauptänderungen

### 1. Befehle vereinheitlicht
**Problem**: Überall stand `npx playwright`, aber Playwright ist global als `playwright` installiert

**Lösung**:
- 45+ Vorkommen von `npx playwright` → `playwright` korrigiert
- Alle JSON Context-Dateien aktualisiert
- Alle JS MCP-Server aktualisiert
- CLAUDE.md aktualisiert

### 2. Verzeichnisstruktur vereinheitlicht
**Problem**: Inkonsistente Pfade (`playwright-tests/` vs `playwright/tests/`)

**Lösung**:
- **Standardisiert auf:**
  - `playwright/tests/` - Alle Test-Dateien
  - `playwright/results/` - Alle Screenshots/Artifacts
  - `playwright/report/` - HTML Reports

### 3. npx-wrapper erstellt
**Problem**: Alte Scripts/Dokumentation verwenden `npx playwright`

**Lösung**:
- `docker/bin/npx-wrapper` erstellt
- Redirects `npx playwright` → `playwright` automatisch
- Andere npx-Befehle funktionieren normal
- Wird automatisch in beiden Containern installiert (dev + flow)

## Geänderte Dateien

### MCP Context Files
1. `mcp/context/playwright/playwright-directories.json`
   - Komplett neu strukturiert
   - Klare Anweisungen für Claude Code
   - Korrekte Befehle und Pfade

2. `mcp/context/playwright/playwright.mcp.json`
   - Alle CLI-Befehle korrigiert
   - Installation-Hinweise hinzugefügt

3. `mcp/context/claude-flow/claude-flow.mcp.json`
   - Alle Workflow-Befehle aktualisiert
   - Verzeichnisstruktur dokumentiert

4. `mcp/context/playwright/playwright-advanced.mcp.json`
   - Alle Code-Beispiele mit korrekten Pfaden
   - Import-Statements vereinfacht

### MCP Server Files
5. `mcp/servers/playwright-context.js`
   - Beispiele aktualisiert
   - Hinweise hinzugefügt

6. `mcp/servers/playwright-advanced-context.js`
   - CI/CD Configs korrigiert
   - Alle `npx playwright` → `playwright`

### Wrapper Scripts
7. `docker/bin/npx-wrapper` (NEU)
   - Redirects `npx playwright` → `playwright`
   - Pass-through für andere npx-Befehle

8. `docker/bin/npx-wrapper-install` (NEU)
   - Installations-Script für Wrapper

### Entrypoint Scripts
9. `docker/bin/entrypoint.dev`
   - npx-wrapper Installation hinzugefügt

10. `docker/bin/entrypoint.flow`
    - npx-wrapper Installation hinzugefügt

### Dokumentation
11. `CLAUDE.md`
    - Playwright-Befehle aktualisiert
    - Klare Anweisungen für Verzeichnisse

12. `docker/bin/README.md` (NEU)
    - Dokumentation aller Wrapper
    - Verwendungsbeispiele

13. `docker/bin/TEST-NPX-WRAPPER.md` (NEU)
    - Test-Szenarien für npx-wrapper
    - Debugging-Hinweise

## Für Claude Code nun eindeutig

### Befehle
```bash
# RICHTIG (wird verwendet):
playwright test
playwright codegen
playwright show-report

# FUNKTIONIERT AUCH (durch Wrapper):
npx playwright test
npx playwright codegen
npx playwright show-report
```

### Verzeichnisse
```javascript
// Test speichern:
'playwright/tests/example.spec.js'

// Screenshot speichern:
await page.screenshot({ path: 'playwright/results/screenshot.png' });

// Report ansehen:
playwright show-report
```

### Import
```javascript
// Bevorzugt (funktioniert durch NODE_PATH):
const { chromium } = require('playwright');
const { test, expect } = require('@playwright/test');

// Alternative (absoluter Pfad):
const { chromium } = require('/usr/local/lib/node_modules/playwright');
```

## Vorteile

### Für Entwickler
- ✅ Alte Scripts mit `npx playwright` funktionieren weiterhin
- ✅ Keine Änderungen an bestehender Dokumentation nötig
- ✅ Konsistente Befehle in allen Umgebungen

### Für Claude Code
- ✅ Eindeutige Anweisungen ohne Widersprüche
- ✅ Klare Verzeichnisstruktur
- ✅ Alle Context-Dateien konsistent
- ✅ Keine Verwirrung durch `npx` vs. global

### Performance
- ✅ Direkter Aufruf von `playwright` (kein npx-Overhead)
- ✅ Wrapper nur aktiv wenn nötig
- ✅ Keine zusätzlichen npm-Installationen

## Testen

### In claude-flow Container
```bash
# Test 1: Wrapper funktioniert
npx playwright --version
# Sollte zeigen: Version 1.x.x (via wrapper → playwright)

# Test 2: Direkter Befehl funktioniert
playwright --version
# Sollte zeigen: Version 1.x.x

# Test 3: Andere npx-Befehle funktionieren
npx cowsay hello
# Sollte zeigen: ASCII Kuh (via echter npx)

# Test 4: Test ausführen
playwright test playwright/tests/
# Sollte Tests ausführen
```

## Migration

### Bestehende Projekte
Keine Änderungen nötig! Der Wrapper stellt Kompatibilität sicher.

### Neue Projekte
Verwenden Sie direkt `playwright` Befehle für beste Performance:
```bash
playwright test
playwright codegen
playwright show-report
```

## Nächste Schritte

1. **Docker Images rebuilden**
   ```bash
   ./docker/build.sh
   ```

2. **Container neu starten**
   ```bash
   claude-flow --clean  # Alte Container entfernen
   claude-flow          # Neu starten mit Wrapper
   ```

3. **Testen**
   - Wrapper-Funktionalität prüfen
   - Playwright-Tests ausführen
   - MCP Context-Dateien validieren

## Notizen

- Alle 45+ Vorkommen von `npx playwright` wurden korrigiert
- Nur 5 verbleibende Erwähnungen sind Warnungen/Hinweise
- Wrapper ist transparent und benötigt keine Konfiguration
- Funktioniert in beiden Containern (dev + flow)
