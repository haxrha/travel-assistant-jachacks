import from "@jac/runtime" { useNavigate }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { Mic01Icon, MicOff01Icon, SparklesIcon, AiBrain01Icon, Wallet01Icon, Tick02Icon }
import from .ui.button { Button }
import from .ui.card { Card, CardContent, CardHeader, CardTitle, CardDescription }
import from .ui.textarea { Textarea }
import from .ui.field { Field, FieldLabel, FieldDescription }
import from .ui.badge { Badge }
import from "sonner" { toast }
import from ..lib.session { get_session_id }
import from ..lib.speech { play_speech, speech_recognition_supported, make_recognizer }
sv import from ..services.trips { plan_trip, gemini_status, TripView }
sv import from ..services.voice { speak_text, SpeechResult }

glob EXAMPLES: list[str] = [
    "3 days in Lisbon under 1500 dollars. I always want an aisle seat and I'm vegetarian.",
    "A long weekend in Kyoto in April, hotels no more than 150 a night, no red-eye flights.",
    "Plan 4 days in Mexico City for food and museums."
];

def:pub NewTrip() -> JsxElement {
    has prompt: str = "",
        listening: bool = False,
        planning: bool = False,
        status: str = "",
        gemini_ready: bool = False,
        active_model: str = "gemini/gemini-2.5-flash",
        error: str = "",
        recognizer: any = None,
        roster: list[dict] = [
            {"name": "Alex Morgan", "role": "Product", "preference": "Aisle seat; vegetarian"},
            {"name": "Jordan Lee", "role": "Engineering", "preference": "Quiet hotel; avoid red-eyes"},
            {"name": "Samira Patel", "role": "Finance", "preference": "Keep team total below $4,000"},
            {"name": "Carlos Reyes", "role": "Design", "preference": "Local architecture and walkable neighborhoods"}
        ];
    navigate = useNavigate();

    async def check_gemini() -> None {
        try {
            cfg = await gemini_status();
            gemini_ready = cfg["key_present"];
            active_model = cfg["model"];
        } except Exception {
            gemini_ready = False;
        }
    }

    def stop_listening() -> None {
        if recognizer { recognizer.stop(); }
        listening = False;
    }

    def start_listening() -> None {
        error = "";
        if not speech_recognition_supported() {
            error = "Voice input needs Chrome, Edge or Safari. You can type your request instead.";
            return;
        }
        rec = make_recognizer();
        base = prompt;
        rec.onresult = lambda (e: any) {
            text = "";
            for i in range(e.results.length) {
                text = text + e.results[i][0].transcript;
            }
            prompt = (base + " " + text).strip();
        };
        rec.onerror = lambda (e: any) {
            error = "Microphone error: " + str(e.error);
            listening = False;
        };
        rec.onend = lambda { listening = False; };
        recognizer = rec;
        listening = True;
        status = "Listening. Describe where, when, budget and any preferences.";
        rec.start();
    }

    async def submit() -> None {
        if not prompt.strip() or planning { return; }
        stop_listening();
        planning = True;
        error = "";
        status = "Planner agent is recalling your preferences and drafting the itinerary...";
        try {
            trip: TripView = await plan_trip(get_session_id(), prompt, roster);
            line = "Your " + trip.title + " is ready. " + trip.summary;
            status = "Speaking the confirmation...";
            try {
                speech: SpeechResult = await speak_text(line);
                play_speech(speech.audio_base64, speech.mime, line);
            } except Exception {
                play_speech("", "", line);
            }
            toast.success("Trip planned: " + trip.title);
            navigate("/trips/" + trip.id);
        } except Exception as e {
            error = "Planning failed. " + str(e);
            status = "";
        }
        planning = False;
    }

    return <div className="grid gap-6 lg:grid-cols-3">
        <div className="flex flex-col gap-6 lg:col-span-2">
            <div className="flex flex-col gap-1">
                <h1 className="text-2xl font-semibold tracking-tight">Plan a trip by voice</h1>
                <p className="text-sm text-muted-foreground">Plan a company offsite with a shared budget, team preferences and a decision trail.</p>
            </div>
            <Card className="shadow-sm">
                <CardContent className="flex flex-col gap-6 pt-2">
                    <div className="flex flex-wrap items-center justify-between gap-3 rounded-xl border bg-muted/40 pt-3 pb-3 pl-4 pr-4">
                        <div><p className="text-sm font-medium">Wayport Labs · Lisbon offsite</p><p className="text-xs text-muted-foreground">3 days · 4 teammates · $4,000 shared budget</p></div>
                        <Button variant="outline" size="sm" onClick={lambda { prompt = "Plan a 3-day company offsite in Lisbon for Wayport Labs. Total team budget is $4,000. Include flights, centrally located lodging, a team dinner and a half-day strategy session."; }}>Load demo trip</Button>
                    </div>
                    <div className="flex flex-col items-center gap-4 pt-4 pb-2">
                        <button
                            type="button"
                            aria-label={"Stop listening" if listening else "Start voice request"}
                            onClick={stop_listening if listening else start_listening}
                            className={"relative flex size-24 items-center justify-center rounded-full shadow-lg transition-all " + ("bg-destructive text-white animate-pulse" if listening else "bg-primary text-primary-foreground hover:scale-105")}
                        >
                            <HugeiconsIcon icon={MicOff01Icon if listening else Mic01Icon} strokeWidth={2} className="size-10" />
                        </button>
                        <p className="text-sm text-muted-foreground">{"Listening... tap to stop" if listening else "Tap to speak your trip"}</p>
                    </div>
                    <Field>
                        <FieldLabel htmlFor="prompt">Trip request</FieldLabel>
                        <Textarea
                            id="prompt"
                            rows={4}
                            value={prompt}
                            onChange={lambda (e: ChangeEvent) { prompt = e.target.value; }}
                            placeholder="3 days in Lisbon under $1,500. Aisle seat, vegetarian, no red-eyes."
                        />
                        <FieldDescription>Your spoken words appear here. Edit before planning if needed.</FieldDescription>
                    </Field>
                    <div className="flex flex-wrap gap-2">
                        {for ex in EXAMPLES {
                            <Button key={ex} variant="outline" size="sm" onClick={lambda { prompt = ex; }}>{ex[:42] + "..."}</Button>
                        }}
                    </div>
                    {error and <p className="text-sm text-destructive">{error}</p>}
                    <div className="flex flex-wrap items-center justify-between gap-3">
                        <div className="flex flex-col gap-1">
                            <span className={"text-xs font-medium " + ("text-emerald-400" if gemini_ready else "text-amber-400")}>{"Gemini key detected" if gemini_ready else "Check Gemini connection"}</span>
                            <span className="text-xs text-muted-foreground">{"Model: " + active_model if gemini_ready else "Ensure GEMINI_API_KEY is saved in Settings > Environment."}</span>
                            <span className="text-xs text-muted-foreground">{status}</span>
                        </div>
                        <Button variant="outline" size="sm" onClick={check_gemini}>Check Gemini</Button>
                        <Button size="lg" className="shadow-sm" disabled={planning or not prompt.strip()} onClick={submit}>
                            <HugeiconsIcon icon={SparklesIcon} strokeWidth={2} />
                            {"Planning..." if planning else "Plan trip"}
                        </Button>
                    </div>
                </CardContent>
            </Card>
        </div>
        <Card className="h-fit shadow-sm">
            <CardHeader>
                <CardTitle>How the agents work</CardTitle>
                <CardDescription>Every step lands in the trip's audit trail.</CardDescription>
            </CardHeader>
            <CardContent className="flex flex-col gap-4">
                <div className="rounded-xl border bg-muted/40 p-3">
                    <p className="mb-2 text-xs font-semibold tracking-wide text-muted-foreground">WAYPORT LABS · SAMPLE TEAM</p>
                    <div className="flex flex-col gap-2">
                        {for person in roster {
                            <div key={person["name"]} className="flex items-start justify-between gap-2 text-xs">
                                <span className="font-medium">{person["name"]}</span>
                                <span className="max-w-[60%] text-right text-muted-foreground">{person["role"] + " · " + person["preference"]}</span>
                            </div>
                        }}
                    </div>
                </div>
                <div className="flex items-start gap-3">
                    <div className="flex size-9 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary"><HugeiconsIcon icon={AiBrain01Icon} strokeWidth={2} className="size-4" /></div>
                    <div><p className="text-sm font-medium">Memory agent <Badge variant="secondary" className="ml-1">Backboard</Badge></p><p className="text-xs text-muted-foreground">Opens a new thread on your personal assistant with memory Auto, recalling facts from past trips.</p></div>
                </div>
                <div className="flex items-start gap-3">
                    <div className="flex size-9 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary"><HugeiconsIcon icon={SparklesIcon} strokeWidth={2} className="size-4" /></div>
                    <div><p className="text-sm font-medium">Planner agent</p><p className="text-xs text-muted-foreground">Builds a day-by-day itinerary that respects what it remembers.</p></div>
                </div>
                <div className="flex items-start gap-3">
                    <div className="flex size-9 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary"><HugeiconsIcon icon={Wallet01Icon} strokeWidth={2} className="size-4" /></div>
                    <div><p className="text-sm font-medium">Financial agent</p><p className="text-xs text-muted-foreground">Checks the plan against your budget and flags overruns.</p></div>
                </div>
                <div className="flex items-start gap-3">
                    <div className="flex size-9 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary"><HugeiconsIcon icon={Tick02Icon} strokeWidth={2} className="size-4" /></div>
                    <div><p className="text-sm font-medium">Booking agent <Badge variant="secondary" className="ml-1">ElevenLabs</Badge></p><p className="text-xs text-muted-foreground">Confirms reservations and reads the result back to you out loud.</p></div>
                </div>
            </CardContent>
        </Card>
    </div>;
}
