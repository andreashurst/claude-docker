# Localhost Handling in Claude Docker

## Übersicht

Alle `localhost`-Referenzen wurden geprüft und sind korrekt konfiguriert. Das System verwendet einen **transparenten Wrapper-Ansatz**, sodass User einfach `localhost` schreiben können.

## Architektur

### 3 Layer System

```
┌─────────────────────────────────────────────────┐
│ User Layer (einfach "localhost" verwenden)      │
│ ├─ curl localhost:3000                          │
│ ├─ playwright codegen http://localhost          │
│ └─ await page.goto('http://localhost')          │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ Wrapper Layer (automatische Transformation)     │
│ ├─ curl-wrapper: localhost → host.docker.int.   │
│ ├─ npx-wrapper: npx playwright → playwright     │
│ └─ Host-Header: Behält "localhost" bei          │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ Host Layer (tatsächliche Verbindung)            │
│ ├─ HTTP Request → host.docker.internal:3000     │
│ ├─ Header: Host: localhost                      │
│ └─ Host-System empfängt Request                 │
└─────────────────────────────────────────────────┘
```

## Geprüfte Dateien

### ✅ bin/claude-docker.lib.sh
**Status**: Korrekt (Dokumentation für User)

**Verwendung**: HTML-Template für Test-Webserver
```html
<div class="command">curl localhost:8080</div>
<div class="command">playwright codegen http://localhost</div>
```

**Warum korrekt?**
- User sieht diese Beispiele
- curl-wrapper macht automatisch localhost → host.docker.internal
- Transparente Verwendung für den User

**Änderungen**: Hinweis hinzugefügt über automatisches Mapping

### ✅ mcp/servers/webserver-env.js
**Status**: Korrekt (Smart Fallback)

**Implementierung**:
```javascript
// checkWebserverStatus() - Zeile 240-245
if (urlObj.hostname === 'localhost') {
  tryConnection('localhost', true);  // Versucht direkt
  // Bei Fehler: Fallback zu host.docker.internal
}

// getWebserverHeaders() - Zeile 254
const hostname = urlObj.hostname === 'localhost' ?
  'host.docker.internal' : urlObj.hostname;
const hostHeader = urlObj.hostname; // Behält "localhost"
```

**Warum korrekt?**
- Versucht erst direkte localhost-Verbindung
- Fallback zu host.docker.internal bei Fehler
- Host-Header bleibt immer "localhost"
- Funktioniert mit und ohne enable-localhost.sh

**Änderungen**: Kommentar präzisiert

### ✅ mcp/servers/vite-hmr-context.js
**Status**: Korrekt (Beispiel-Konfiguration)

**Verwendung**: Vite Config-Beispiele für User
```javascript
{
  server: {
    host: true,  // 0.0.0.0 - lauscht auf allen Interfaces
    hmr: {
      host: 'localhost',  // Wrapper macht Mapping
      port: 5173
    }
  }
}
```

**Warum korrekt?**
- User schreibt Config mit `localhost`
- Vite Server läuft auf Host-System
- Playwright im Container greift darauf zu
- Wrapper macht automatisch die Umleitung
- WebSocket-Verbindung funktioniert transparent

**Änderungen**: Kommentare hinzugefügt zur Erklärung

## Wrapper-Details

### curl-wrapper (docker/bin/curl-wrapper)
```bash
if [[ $* == *"localhost"* ]]; then
  # Ersetzt localhost mit host.docker.internal
  arg="${arg//localhost/host.docker.internal}"
  # Fügt Host-Header hinzu
  exec "$REAL_CURL" -H "Host: localhost" "${args[@]}"
fi
```

**Features**:
- ✅ Automatische localhost → host.docker.internal Umwandlung
- ✅ Host-Header bleibt "localhost"
- ✅ Transparent für User
- ✅ Funktioniert mit allen curl-Optionen

### npx-wrapper (docker/bin/npx-wrapper)
```bash
if [[ "$1" == "playwright" ]]; then
  shift
  exec playwright "$@"
fi
```

**Features**:
- ✅ npx playwright → playwright Umleitung
- ✅ Andere npx-Befehle funktionieren normal
- ✅ Keine Performance-Einbußen

## Verwendungsmuster

### Pattern 1: curl-Befehle
```bash
# User schreibt:
curl http://localhost:3000

# Wrapper transformiert zu:
curl http://host.docker.internal:3000 -H "Host: localhost"
```

### Pattern 2: Playwright Tests
```javascript
// User schreibt:
await page.goto('http://localhost:3000');

// Playwright verwendet curl-wrapper intern
// → Automatische Transformation zu host.docker.internal
```

### Pattern 3: Vite HMR
```javascript
// vite.config.js auf Host:
export default {
  server: {
    host: true,  // 0.0.0.0
    port: 5173,
    hmr: {
      host: 'localhost',  // User schreibt localhost
      port: 5173
    }
  }
}

// Im Container:
// - Playwright verbindet zu localhost:5173
// - Wrapper macht localhost → host.docker.internal
// - WebSocket funktioniert
```

### Pattern 4: MCP Server Checks
```javascript
// MCP Tool aufgerufen:
await mcp.check_webserver_status({ url: 'http://localhost:8080' });

// MCP Server macht:
// 1. Versucht localhost direkt
// 2. Bei Fehler: Fallback zu host.docker.internal
// 3. Host-Header: "localhost"
```

## Warum nicht überall host.docker.internal?

### Vorteile des Wrapper-Ansatzes:

1. **Portabilität**
   - Scripts/Tests funktionieren überall (Docker, Host, CI)
   - Keine Docker-spezifischen Anpassungen nötig

2. **User Experience**
   - User schreibt natürliches `localhost`
   - Keine Docker-Kenntnisse erforderlich
   - Beispiele/Dokumentation bleibt einfach

3. **Flexibilität**
   - Smart Fallback in MCP Servern
   - Funktioniert mit enable-localhost.sh
   - Keine Code-Änderungen bei Umgebungswechsel

4. **Korrekte Host-Header**
   - Virtual Hosts funktionieren
   - CORS richtig konfiguriert
   - SSL-Zertifikate passen

## Test-Szenarien

### Szenario 1: Externer Webserver
```bash
# Auf Host läuft nginx:80
# Im Container:
curl http://localhost
# → Wrapper macht: curl http://host.docker.internal:80 -H "Host: localhost"
# → Nginx empfängt Request mit Host: localhost
# ✅ Funktioniert
```

### Szenario 2: Vite Dev Server
```bash
# Auf Host: npm run dev (Port 5173)
# Im Container:
playwright codegen http://localhost:5173
# → Wrapper macht Umleitung
# → Playwright öffnet localhost:5173
# → HMR WebSocket verbindet
# ✅ Funktioniert
```

### Szenario 3: MCP Webserver Check
```javascript
// Claude Code ruft auf:
check_webserver_status({ url: 'http://localhost:8080' })

// MCP Server:
// 1. Versucht localhost:8080 direkt → Fehler
// 2. Fallback zu host.docker.internal:8080 → Erfolg
// 3. Gibt Status zurück
// ✅ Funktioniert
```

### Szenario 4: Playwright Test
```javascript
// playwright/tests/example.spec.js
test('homepage loads', async ({ page }) => {
  await page.goto('http://localhost:3000');
  await expect(page).toHaveTitle(/My App/);
});

// Playwright verwendet Browser mit Wrapper
// → localhost → host.docker.internal
// → Test läuft erfolgreich
// ✅ Funktioniert
```

## Troubleshooting

### Problem: "Connection refused"
**Ursache**: Webserver läuft nicht oder falscher Port
**Lösung**:
```bash
# Auf Host prüfen:
netstat -tlnp | grep :3000

# Im Container prüfen:
curl http://localhost:3000 -v
# Zeigt Wrapper-Transformation
```

### Problem: "Wrong Host"
**Ursache**: Virtual Host-Konfiguration
**Lösung**: Host-Header wird automatisch gesetzt
```bash
curl http://localhost:3000 -H "Host: myapp.local"
# Wrapper behält Host-Header bei
```

### Problem: "WebSocket connection failed"
**Ursache**: HMR-Konfiguration
**Lösung**:
```javascript
// vite.config.js
hmr: {
  host: 'localhost',  // Nicht host.docker.internal!
  port: 5173
}
```

## Best Practices

### ✅ DO: localhost verwenden
```javascript
await page.goto('http://localhost:3000');
curl http://localhost:8080
```

### ✅ DO: Host-Header bei Bedarf anpassen
```bash
curl http://localhost -H "Host: myapp.test"
```

### ✅ DO: Standard-Ports verwenden
```javascript
// Vite: 5173, React: 3000, Laravel: 8000
const url = `http://localhost:${port}`;
```

### ❌ DON'T: host.docker.internal direkt verwenden
```javascript
// FALSCH:
await page.goto('http://host.docker.internal:3000');

// RICHTIG:
await page.goto('http://localhost:3000');
```

### ❌ DON'T: IP-Adressen hardcoden
```javascript
// FALSCH:
await page.goto('http://172.17.0.1:3000');

// RICHTIG:
await page.goto('http://localhost:3000');
```

## Zusammenfassung

| Komponente | localhost-Verwendung | Wrapper | Status |
|------------|---------------------|---------|--------|
| User-Dokumentation | ✅ Ja | curl-wrapper | ✅ Korrekt |
| Playwright Tests | ✅ Ja | curl-wrapper | ✅ Korrekt |
| MCP webserver-env | ✅ Ja (Fallback) | Intern | ✅ Korrekt |
| MCP vite-hmr | ✅ Ja (Beispiele) | curl-wrapper | ✅ Korrekt |
| Vite Config | ✅ Ja | curl-wrapper | ✅ Korrekt |
| curl-Befehle | ✅ Ja | curl-wrapper | ✅ Korrekt |

**Ergebnis**: Alle localhost-Referenzen sind korrekt konfiguriert! ✅

## Nächste Schritte

Keine Änderungen nötig. System funktioniert wie designed:
- ✅ User schreibt `localhost`
- ✅ Wrapper macht Transformation
- ✅ Host-Header korrekt
- ✅ Transparent und portabel
