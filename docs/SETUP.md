# YouTube Faceless Automation - Setup Guide

**Workflow Version:** 1.2  
**Status:** ✅ Production Ready  
**Total Nodes:** 25

---

## 📋 ARCHITEKTUR

### Blocks:
1. **Input** (4) → Webhook, Validation, Gate, Error 400
2. **Content** (2) → Claude Langchain, Parser
3. **Audio** (5) → ElevenLabs, Timing, Upload, URL, Calculate
4. **Scenes** (1) → Split Out
5. **Runway** (6) → Loop, Text→Image, Poll, Image→Video, Poll, Aggregate
6. **Assembly** (4) → Modifications, Render, Wait, Success
7. **Error** (3) → Trigger, Log, Error 500

### Flow:
```
POST → Validation → Claude → ElevenLabs → Supabase → Calculate
  → Split Out → Loop[Runway] → Aggregate → Creatomate → Success
```

---

## ✅ SETUP

### 1. Supabase
- [x] Bucket `audio` erstellt
- [x] Table `workflow_logs`

### 2. n8n Credentials

| Type | Name | Details |
|------|------|---------|
| Anthropic API | Anthropic account | API Key |
| ElevenLabs API | ElevenLabs account | API Key |
| HTTP Bearer | Runway Bearer Auth | Token |
| HTTP Bearer | Creatomate Bearer | Token |
| Supabase API | Supabase NovaCoreDB | Host + Key |

### 3. Environment Variables

```bash
CREATOMATE_TEMPLATE_ID="75b2838d-bbdf-42ee-86b1-507e37c85760"
N8N_WEBHOOK_BASE="https://n8n.yourdomain.com"
SUPABASE_URL="https://xxx.supabase.co"
SUPABASE_SERVICE_ROLE_KEY="eyJ..."
```

**Removed in v1.2:** `ELEVENLABS_VOICE_ID` (hardcoded: CVcPLXStXPeDxhrSflDZ)

### 4. Creatomate Template

Required elements:
- Audio-Track (source, duration)
- Scene-1 to Scene-12:
  - Scene-X-Video (source)
  - Scene-X-Text (optional)
  - Scene-X (duration, time)

Unused scenes: duration=0

---

## 🚀 DEPLOYMENT

```bash
# Test
curl -X POST https://n8n.com/webhook/youtube-automation \
  -H "Content-Type: application/json" \
  -d '{"topic":"AI Healthcare","style":"documentary","target_duration":60}'

# Timeline: 15-25min
# Input: <1s
# Claude: 10-30s
# ElevenLabs: 5-15s
# Runway: ~14min (4 scenes)
# Creatomate: 2-5min
```

---

## 🆕 V1.2 CHANGES

**New Nodes:**
- Split Out (scene array)
- Claude Langchain (replaces HTTP)

**Modified:**
- ElevenLabs: Binary file (not with-timestamps)
- Timing: Duration from file size
- Polls: this.helpers.httpRequest
- Creatomate: duration=0 for unused scenes

**Credentials:**
- Native ElevenLabs API
- Anthropic Langchain
- Bearer Auth for Runway/Creatomate

---

## 📊 MONITORING

```sql
SELECT * FROM workflow_logs 
WHERE workflow_name = 'youtube-automation'
ORDER BY timestamp DESC LIMIT 20;
```

**Common Errors:**
- Claude: Check Anthropic credential
- ElevenLabs: Check API key
- Runway: API limit / timeout
- Creatomate: Template ID wrong

---

## 💰 COST

**60s video (4 scenes): ~$0.84**
- Claude: $0.05
- ElevenLabs: $0.03
- Runway: $0.60 (71%)
- Creatomate: $0.16

---

## 🎯 CHECKLIST

- [ ] 5 Credentials
- [ ] .env configured
- [ ] Creatomate template
- [ ] Workflow active
- [ ] Test request
- [ ] Download video 🎬
