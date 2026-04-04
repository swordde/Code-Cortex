# Pre-demo integration checklist

## Member 3 (Go backend)
[ ] curl http://192.168.1.54:8000/model/status returns JSON with model_loaded: true
[ ] POST /classify returns correct priority for a test notification
[ ] POST /cortex/reply returns a non-empty reply for a Medium priority message
[ ] POST /feedback stores a corrective sample successfully
[ ] GET /cortex/log returns recent activity

## Member 4 (Flutter)
[ ] snp_api.dart imported, http package added to pubspec.yaml
[ ] getModelStatus() returns without SnpApiException
[ ] classify() returns ClassifyResponse with correct priority field
[ ] cortexReply() returns CortexReplyResponse with action field
[ ] voiceVerify() returns VoiceVerifyResponse with match field
[ ] startVoiceAssistant() completes without error
[ ] sendReaderCommand(transcript: 'read my high priority messages') returns a response

## Both
[ ] Server IP has not changed (check ipconfig / ip a on Member 1's machine)
[ ] Port 8000 is open in firewall
[ ] Server started with: uvicorn ai.api.main:app --host 0.0.0.0 --port 8000
[ ] All team members on same WiFi network
