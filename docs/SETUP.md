# YouTube Faceless Automation - Setup Guide

**Workflow ID:** `4xpZZ3ltwWU03lc6`  
**Status:** ✅ Bereit für Deployment  
**Total Nodes:** 23 (komplett)

---

## 📋 ARCHITEKTUR ÜBERBLICK

### Blocks:
1. **Input Layer** (4 Nodes) → Webhook, Validation, Gate, Error 400
2. **Content Generation** (2 Nodes) → Claude Worker, Parser
3. **Audio Master** (5 Nodes) → ElevenLabs, Timing, Upload, URL, Calculate
4. **Runway Video Pipeline** (6 Nodes) → Loop, Text→Image, Poll, Image→Video, Poll, Aggregate
5. **Creatomate Assembly** (4 Nodes) → Modifications, Render, Wait, Success 200
6. **Error Handling** (3 Nodes) → Trigger, Log, Error 500

### Datenfluss:
```
POST /youtube-automation
  → Validation → Claude → ElevenLabs → Supabase → Calculate
    → Loop [Runway Text→Image → Poll → Image→Video → Poll] × N Scenes
      → Aggregate → Creatomate → Wait → Success 200 ✅
```

---

## ✅ DEPLOYMENT CHECKLISTE

### PHASE 1: SUPABASE (✅ FERTIG)
- [x] Storage Bucket `audio` erstellt
- [x] Tabelle `workflow_logs` erstellt
- [x] Indexes konfiguriert

### PHASE 2: N8N CREDENTIALS (❌ TODO)

**4 Credentials erstellen in:** Settings → Credentials → New

#### 1. Anthropic API
```
Type: Anthropic API
Name: anthropicApi
API Key: sk-ant-...
```

#### 2. ElevenLabs
```
Type: Header Auth
Name: elevenlabsApiKey
Header Name: xi-api-key
Header Value: YOUR_KEY
```

#### 3. Runway
```
Type: Header Auth
Name: runwayApiKey
Header Name: Authorization
Header Value: Bearer YOUR_KEY
```

#### 4. Creatomate
```
Type: Header Auth
Name: creatomateApiKey
Header Name: Authorization
Header Value: Bearer YOUR_KEY
```

### PHASE 3: ENVIRONMENT VARIABLES (❌ TODO)

**Datei:** `.env.template` → kopieren nach `.env` und ausfüllen

```bash
# 1. WORKER SYSTEM PROMPT
WORKER_SYSTEM_PROMPT="[Siehe worker_system_prompt.txt - als einzeilige String]"

# 2. SERVICE IDs
ELEVENLABS_VOICE_ID="21m00Tcm4TlvDq8ikWAM"  # Deine Voice ID
CREATOMATE_TEMPLATE_ID="YOUR_TEMPLATE_ID"   # Template ID

# 3. URLS
N8N_WEBHOOK_BASE="https://n8n.yourdomain.com"
SUPABASE_URL="https://ywdwvjriklaevktswnwe.supabase.co"
SUPABASE_SERVICE_ROLE_KEY="eyJhbGci..."
```

**Wo finde ich was?**

| Variable | Quelle |
|----------|--------|
| ELEVENLABS_VOICE_ID | https://elevenlabs.io/app/voice-lab → Voice → Copy ID |
| CREATOMATE_TEMPLATE_ID | https://creatomate.com/templates → Template → Settings |
| SUPABASE_SERVICE_ROLE_KEY | https://supabase.com/dashboard → Project → Settings → API |

### PHASE 4: CREATOMATE TEMPLATE (❌ TODO)

**Template erstellen in:** https://creatomate.com/templates

**Required Elements:**
```
Audio-Track (Audio Source)
  └─ Modifications: url, duration

Scene-1 (Composition)
  ├─ Scene-1-Video (Video Source)
  │   └─ Modifications: url
  ├─ Scene-1-Text (Text Element, optional)
  │   └─ Modifications: text, time, duration
  └─ Modifications: duration, time

Scene-2, Scene-3, ... (repeat pattern)
```

**Wichtig:**
- Template muss dynamische Modifications unterstützen
- Max 12 Scenes vorbereiten
- Text Overlays optional (können null sein)

---

## 🚀 DEPLOYMENT

### 1. Workflow Aktivieren
```
n8n UI → Workflows → YouTube Automation v1.2 → Toggle Active
```

### 2. Webhook URL
```
https://your-n8n.com/webhook/youtube-automation
```

### 3. Test Request
```bash
curl -X POST https://your-n8n.com/webhook/youtube-automation \
  -H "Content-Type: application/json" \
  -d '{
    "topic": "The Future of AI in Healthcare",
    "style": "documentary",
    "target_duration": 60
  }'
```

### 4. Expected Timeline
```
Input Validation:       < 1s
Claude Generation:      10-30s
ElevenLabs TTS:         5-15s
Supabase Upload:        2-5s
Runway Loop (4 scenes):
  - Text→Image:         30s × 4 = 2min
  - Image→Video:        3min × 4 = 12min
  Total Runway:         ~14min
Creatomate Render:      2-5min
──────────────────────────────
TOTAL:                  15-25min
```

### 5. Success Response
```json
{
  "status": "success",
  "execution_id": "abc-123",
  "video_url": "https://cdn.creatomate.com/renders/...",
  "audio_duration": 58.4,
  "scenes_count": 4
}
```

---

## 📊 MONITORING

### Check Logs in Supabase
```sql
SELECT * FROM workflow_logs 
WHERE workflow_name = 'youtube-automation'
ORDER BY timestamp DESC
LIMIT 20;
```

### Common Errors

| Error Node | Ursache | Lösung |
|-----------|---------|--------|
| Claude Worker | Invalid API Key | Credential prüfen |
| ElevenLabs TTS | Voice ID nicht gefunden | ELEVENLABS_VOICE_ID prüfen |
| Runway Text to Image | API Limit | Warten oder Upgrade |
| Supabase Upload | Storage Bucket fehlt | Bucket "audio" erstellen |
| Creatomate Render | Template ID falsch | CREATOMATE_TEMPLATE_ID prüfen |

---

## 🔧 TROUBLESHOOTING

### Workflow startet nicht
```bash
# Check: Webhook ist aktiv
curl https://your-n8n.com/webhook/youtube-automation

# Expected: 405 Method Not Allowed (GET statt POST = OK)
# Error 404 = Webhook nicht aktiv
```

### Timeout bei Runway
```
Poll Image Task / Poll Video Task: Max 10min / 20min
Bei Timeout → Manuell Task Status prüfen:
curl https://api.dev.runwayml.com/v1/tasks/{task_id} \
  -H "Authorization: Bearer YOUR_KEY" \
  -H "X-Runway-Version: 2024-11-06"
```

### Claude gibt kein JSON zurück
```
Check: WORKER_SYSTEM_PROMPT in .env korrekt escaped?
Test: Echo $WORKER_SYSTEM_PROMPT | head -n 5
```

---

## 💰 KOSTEN PRO VIDEO

**Basis (60s Video, 4 Scenes):**
- Claude Sonnet 4.5: ~$0.05 (200K tokens)
- ElevenLabs TTS: ~$0.03 (150 chars)
- Runway Gen-4 Turbo: ~$0.60 (4 × 10s @ $0.15/s)
- Creatomate: ~$0.16 (1 render)
- **TOTAL: ~$0.84**

**Bei Scale (100 Videos/Tag):**
- $84/Tag = $2,520/Monat
- Runway ist 71% der Kosten

---

## 📁 FILES

```
/home/claude/
  ├── worker_system_prompt.txt   # Kompletter Claude Prompt
  └── .env.template              # Environment Variables Template

n8n Workflow:
  ID: 4xpZZ3ltwWU03lc6
  Name: YouTube Automation v1.2 - COMPLETE PRODUCTION
```

---

## 🎯 NEXT STEPS

1. [ ] Credentials erstellen (4×)
2. [ ] .env konfigurieren (6 vars)
3. [ ] Creatomate Template erstellen
4. [ ] ElevenLabs Voice auswählen
5. [ ] Workflow aktivieren
6. [ ] Test Request senden
7. [ ] Video downloaden 🎬

**Viel Erfolg! 🚀**