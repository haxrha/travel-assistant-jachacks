"""Browser voice helpers: play ElevenLabs audio, or fall back to speechSynthesis."""

glob _audio: any = None;

cl def _win() -> any {
    return window;
}

cl def:pub play_speech(audio_base64: str, mime: str, fallback_text: str) -> None {
    w: any = _win();
    if audio_base64 {
        if _audio { _audio.pause(); }
        AudioCtor: any = w.Audio;
        _audio = new(AudioCtor, "data:" + mime + ";base64," + audio_base64);
        _audio.play();
        return;
    }
    synth: any = w.speechSynthesis;
    if synth and fallback_text {
        synth.cancel();
        UtterCtor: any = w.SpeechSynthesisUtterance;
        synth.speak(new(UtterCtor, fallback_text));
    }
}

cl def:pub speech_recognition_supported() -> bool {
    w: any = _win();
    if w.SpeechRecognition or w.webkitSpeechRecognition { return True; }
    return False;
}

cl def:pub make_recognizer() -> any {
    w: any = _win();
    Ctor: any = w.SpeechRecognition or w.webkitSpeechRecognition;
    if not Ctor { return None; }
    rec: any = new(Ctor);
    rec.lang = "en-US";
    rec.interimResults = True;
    rec.continuous = False;
    return rec;
}
