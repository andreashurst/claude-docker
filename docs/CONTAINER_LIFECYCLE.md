# Container Lifecycle Management

## 🔄 Container Verhalten nach Neustart

### ✅ **Keine automatischen Neustarts**
Die Container sind so konfiguriert, dass sie **nicht automatisch** nach einem System-Neustart starten:

```yaml
# Docker Compose Konfiguration
restart: "no"  # Keine automatischen Neustarts
```

### 🎯 **Gewünschtes Verhalten implementiert**

Nach einem System-Neustart zeigen die Scripts dieses intelligente Verhalten:

#### **Szenario 1: Laufender Container**
```bash
claude-dev  # oder claude-flow
```
```
Found running container: myproject-claude-dev-1
Use existing running container? (y/N)
```

#### **Szenario 2: Gestoppter Container (nach Neustart)**
```bash
claude-dev  # oder claude-flow
```
```
Found stopped container: myproject-claude-dev-1
Restart existing container (keeps data) or create new one (fresh start)?
  [r] Restart existing container
  [n] Create new container
  [q] Quit
```

### 🔧 **Benutzeroptionen**

#### **Option [r] - Restart existing container**
- ✅ **Behält alle Daten** (npm cache, config, etc.)
- ✅ **Schneller Start** - keine Neuinstallation
- ✅ **Gleiche Container-ID**
- ✅ **Persistent volumes** bleiben erhalten

#### **Option [n] - Create new container**
- ✅ **Frischer Start** - "ohne Gedächtnis"
- ✅ **Neue Installation** von Claude Code
- ✅ **Löscht alten Container**
- ⚠️  **Volumes bleiben** (für Konsistenz)

#### **Option [q] - Quit**
- ✅ **Kein Aktionen**
- ✅ **Script beenden**

### 📊 **Container-Status-Matrix**

| Container-Status | Nach Neustart | Script-Verhalten | Benutzer-Auswahl |
|------------------|---------------|-------------------|-------------------|
| **Laufend** | Läuft weiter | Direkte Verbindung | y/N |
| **Gestoppt** | Bleibt gestoppt | Intelligente Optionen | r/n/q |
| **Nicht vorhanden** | - | Neue Container | Automatisch |

### 🚀 **Implementierung in allen Scripts**

Dieses Verhalten ist in **allen** Script-Varianten implementiert:

- ✅ `scripts/claude-dev-v1` (Docker Compose v1)
- ✅ `scripts/claude-dev-v2` (Docker Compose v2)
- ✅ `scripts/claude-flow-v1` (Docker Compose v1) 
- ✅ `scripts/claude-flow-v2` (Docker Compose v2)

### 🔍 **Technische Details**

#### **Container-Erkennung:**
```bash
# Alle Container (laufend + gestoppt)
CONTAINER=$(docker ps -a --format "{{.Names}}" | grep "^${PROJECT_NAME}.*claude-dev")

# Nur laufende Container  
RUNNING=$(docker ps --format "{{.Names}}" | grep "^${CONTAINER}$")
```

#### **Restart-Logik:**
```bash
if [[ -n "$RUNNING" ]]; then
    # Container läuft bereits
    docker exec -it "$CONTAINER" bash -l
else
    # Container ist gestoppt
    case "$choice" in
        [Rr]) docker start "$CONTAINER" ;;
        [Nn]) docker rm "$CONTAINER" ;;
    esac
fi
```

### 🎯 **Vorteile dieser Implementierung**

1. **🔒 Keine unerwarteten Starts** - Container starten nie automatisch
2. **💾 Daten-Erhaltung** - User kann wählen zwischen Restart/Fresh
3. **⚡ Schneller Neustart** - Existing Container startet sofort
4. **🧹 Saubere Trennung** - Fresh Start für neue Projekte
5. **🎮 Benutzer-Kontrolle** - Alle Optionen klar kommuniziert

### 📝 **Benutzer-Anleitung**

#### **Nach System-Neustart:**

1. **Navigiere zu deinem Projekt:**
   ```bash
   cd /path/to/your/project
   ```

2. **Starte Claude Umgebung:**
   ```bash
   claude-dev    # oder claude-flow
   ```

3. **Wähle gewünschte Option:**
   - **[r]** → Schneller Restart mit allen Daten
   - **[n]** → Frische Umgebung ohne "Gedächtnis"
   - **[q]** → Abbrechen

### ✅ **Problem gelöst!**

Die Container-Lifecycle ist jetzt **exakt wie gewünscht** implementiert:

- ❌ Keine automatischen Neustarts nach System-Neustart
- ✅ Intelligente Erkennung von gestoppten Containern
- ✅ User-Choice zwischen Restart (mit Daten) und Fresh Start
- ✅ Klare Kommunikation der verfügbaren Optionen