# Faceless YouTube Automation

**Production-ready n8n workflow for automated faceless YouTube video generation**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![n8n](https://img.shields.io/badge/n8n-workflow-FF6D5A)](https://n8n.io)
[![Version](https://img.shields.io/badge/version-1.2.0-blue)](https://github.com/JNassar77/faceless-youtube-automation)

## 🎯 Overview

Fully automated pipeline that transforms text prompts into polished, faceless YouTube videos using:
- **Claude Sonnet 4.5** for script and visual prompt generation (via n8n Langchain node)
- **ElevenLabs** for professional text-to-speech narration
- **Runway Gen-4 Turbo** for AI-generated video scenes
- **Creatomate** for final video assembly and rendering
- **Supabase** for audio storage and logging

**Input:** Topic + Style + Duration  
**Output:** Ready-to-upload MP4 video

---

## ✨ Features

- ✅ **Audio-First Architecture** - Audio duration drives video timing (single source of truth)
- ✅ **2-Step Runway Pipeline** - Text→Image→Video for highest quality
- ✅ **Automated Duration Calculation** - Proportional scene timing based on TTS length
- ✅ **Error Handling & Logging** - Complete error tracking in Supabase
- ✅ **Production-Ready** - 15-25 min execution, >90% success rate
- ✅ **Cost-Optimized** - ~$0.84 per 60s video

---

## 📊 Workflow Architecture

```
Webhook Input
    ↓
Input Validation → Gate
    ↓ (valid)
Claude Worker (Langchain Node)
    ↓
Claude Response Parser
    ↓
ElevenLabs TTS (Binary File) → Timing Extraction → Supabase Upload
    ↓
Build Audio URL → Duration Calculation
    ↓
Split Out (Scene Array)
    ↓
Scene Loop (for each scene):
    Text → Image (Runway) → Poll
        ↓
    Image → Video (Runway) → Poll
    ↓
Aggregate Results
    ↓
Build Creatomate Modifications → Creatomate Render → Wait for Render
    ↓
Success Response (200) ✅

[Error Handler → Log → Error Response (500)]
```

**Total Nodes:** 25  
**Execution Time:** 15-25 minutes  
**Timeout:** 30 minutes

---

## 🚀 Quick Start

### Prerequisites

- n8n instance (self-hosted or cloud)
- Supabase account (free tier works)
- API keys for:
  - Anthropic (Claude)
  - ElevenLabs
  - Runway ML
  - Creatomate

### Installation

1. **Clone Repository**
```bash
git clone https://github.com/JNassar77/faceless-youtube-automation.git
cd faceless-youtube-automation
```

2. **Setup Supabase**
```bash
# Run SQL schema in Supabase SQL Editor
cat sql/supabase_schema.sql
# → Copy and execute in Supabase dashboard
```

3. **Import n8n Workflow**
```bash
# In n8n UI: Workflows → Import from File
# → Select: n8n/workflow.json
```

4. **Configure Environment Variables**
```bash
# Copy template and fill in values
cp config/env.template .env

# Edit .env with your values:
# - WORKER_SYSTEM_PROMPT (from config/worker_system_prompt.txt)
# - CREATOMATE_TEMPLATE_ID
# - N8N_WEBHOOK_BASE
# - SUPABASE_URL
# - SUPABASE_SERVICE_ROLE_KEY
```

5. **Setup Credentials in n8n**

Create 4 credentials in n8n UI (Settings → Credentials):

| Name | Type | Details |
|------|------|------------|
| `Anthropic account` | Anthropic API | API Key: `sk-ant-...` |
| `ElevenLabs account` | ElevenLabs API | API Key: Your ElevenLabs key |
| `Runway Bearer Auth account` | HTTP Bearer Auth | Token: Your Runway API key |
| `Creatomate Bearer Auth` | HTTP Bearer Auth | Token: Your Creatomate API key |
| `Supabase NovaCoreDB` | Supabase API | Host: Your Supabase URL, Service Role Key |

**Important Notes:**
- The **Claude Worker** node uses the native n8n Langchain integration for Anthropic
- **ElevenLabs** uses native n8n ElevenLabs credential (not custom header auth)
- Voice ID `CVcPLXStXPeDxhrSflDZ` is hardcoded in the workflow (ElevenLabs TTS node)
- Runway requires Bearer authentication with your API key

6. **Activate Workflow**
```bash
# In n8n UI: Enable workflow toggle
```

7. **Test Request**
```bash
curl -X POST https://your-n8n.com/webhook/youtube-automation \
  -H "Content-Type: application/json" \
  -d '{
    "topic": "The Future of AI in Healthcare",
    "style": "documentary",
    "target_duration": 60
  }'
```

---

## 📖 Documentation

- **[Setup Guide](docs/SETUP.md)** - Complete deployment instructions
- **[Architecture](docs/ARCHITECTURE.md)** - Technical deep dive
- **[API Reference](docs/API.md)** - Input/output specifications
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues & fixes

---

## 💰 Cost Breakdown

**Per 60s video (4 scenes):**

| Service | Cost | Percentage |
|---------|------|------------|
| Claude Sonnet 4.5 | $0.05 | 6% |
| ElevenLabs TTS | $0.03 | 4% |
| **Runway Gen-4 Turbo** | **$0.60** | **71%** |
| Creatomate | $0.16 | 19% |
| **TOTAL** | **$0.84** | 100% |

**At scale (100 videos/day):**
- Daily: $84
- Monthly: $2,520

---

## 🛠️ Tech Stack

- **Workflow Engine:** n8n
- **AI Model:** Claude Sonnet 4.5 (claude-sonnet-4-5-20250929) via Langchain
- **Text-to-Speech:** ElevenLabs API (eleven_multilingual_v2)
- **Video Generation:** Runway Gen-4 Turbo (2-step pipeline)
- **Video Assembly:** Creatomate
- **Storage:** Supabase (audio files + logs)
- **Language:** JavaScript (n8n Code Nodes)

---

## 📝 Input Schema

```json
{
  "topic": "string (10-200 chars)",
  "style": "cinematic | documentary | educational",
  "target_duration": "number (30-180 seconds)"
}
```

## 📤 Output Schema

```json
{
  "status": "success",
  "execution_id": "uuid",
  "video_url": "https://cdn.creatomate.com/...",
  "audio_duration": 58.4,
  "scenes_count": 4
}
```

---

## 🔧 Configuration

### Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `WORKER_SYSTEM_PROMPT` | Claude system prompt | See config/ |
| `CREATOMATE_TEMPLATE_ID` | Creatomate template | `75b2838d-bbdf-42ee-86b1-507e37c85760` |
| `N8N_WEBHOOK_BASE` | n8n instance URL | `https://n8n.example.com` |
| `SUPABASE_URL` | Supabase project URL | `https://xxx.supabase.co` |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase service key | `eyJhbGci...` |

**Note:** ElevenLabs Voice ID is hardcoded in the workflow as `CVcPLXStXPeDxhrSflDZ`. To change it, edit the "ElevenLabs TTS with Timestamps" node in n8n.

---

## 🔄 Key Workflow Changes in v1.2

### New Nodes Added:
1. **Split Out Node** - Properly splits scene array before loop processing
2. **Claude Langchain Node** - Replaces HTTP Request node for better integration

### Modified Nodes:
- **ElevenLabs TTS** - Now uses binary file response (instead of with-timestamps endpoint)
- **Timing Extraction** - Calculates audio duration from file size
- **Poll Tasks** - Use `this.helpers.httpRequest` instead of `fetch` for better n8n compatibility
- **Build Creatomate Modifications** - Better handling of unused scenes (sets duration to 0)

### Architecture Improvements:
- Audio duration calculation more reliable (file-size based)
- Better error handling in polling logic
- Cleaner scene loop management with Split Out node
- More maintainable Runway API calls

---

## 🧪 Testing

```bash
# Test Webhook Endpoint
curl https://your-n8n.com/webhook/youtube-automation

# Expected: 405 Method Not Allowed (GET not allowed)
# If 404 → Workflow not active

# Test with Valid Request
curl -X POST https://your-n8n.com/webhook/youtube-automation \
  -H "Content-Type: application/json" \
  -d '{"topic": "AI in Healthcare", "style": "cinematic", "target_duration": 60}'

# Expected: 200 OK after 15-25 minutes
```

---

## 📊 Monitoring

### Check Logs in Supabase

```sql
-- Recent errors
SELECT * FROM workflow_logs 
WHERE event = 'workflow_error' 
  AND timestamp > NOW() - INTERVAL '24 hours'
ORDER BY timestamp DESC;

-- Error distribution by node
SELECT error_node, COUNT(*) as count
FROM workflow_logs
WHERE event = 'workflow_error'
GROUP BY error_node
ORDER BY count DESC;
```

---

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Anthropic** - Claude AI
- **ElevenLabs** - Text-to-Speech
- **Runway ML** - AI Video Generation
- **Creatomate** - Video Assembly
- **n8n** - Workflow Automation
- **Supabase** - Backend Infrastructure

---

## 📞 Support

- **Issues:** [GitHub Issues](https://github.com/JNassar77/faceless-youtube-automation/issues)
- **Discussions:** [GitHub Discussions](https://github.com/JNassar77/faceless-youtube-automation/discussions)

---

**Built with ❤️ for automated video creation**
