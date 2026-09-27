"""ElevenLabs text-to-speech for the voice booking agent."""

import os;
import json;
import base64;
import urllib.request;

obj SpeechResult {
    has audio_base64: str = "",
        mime: str = "audio/mpeg",
        fallback: bool = True,
        text: str = "";
}

def:pub speak_text(text: str) -> SpeechResult {
    key = os.environ.get("ELEVENLABS_API_KEY", "") or "";
    if not key or not text.strip() {
        return SpeechResult(fallback=True, text=text);
    }
    voice_id = os.environ.get("ELEVENLABS_VOICE_ID", "") or "21m00Tcm4TlvDq8ikWAM";
    try {
        body = json.dumps(
            {"text": text[:1200], "model_id": "eleven_turbo_v2_5"}
        ).encode("utf-8");
        req = urllib.request.Request(
            f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}",
            data=body,
            headers={
                "xi-api-key": key,
                "Content-Type": "application/json",
                "Accept": "audio/mpeg"
            },
            method="POST"
        );
        with urllib.request.urlopen(req, timeout=60) as resp {
            audio = resp.read();
        }
        return SpeechResult(
            audio_base64=base64.b64encode(audio).decode("ascii"),
            fallback=False,
            text=text
        );
    } except Exception as e {
        print(f"[elevenlabs] tts failed: {str(e)}");
        return SpeechResult(fallback=True, text=text);
    }
}
