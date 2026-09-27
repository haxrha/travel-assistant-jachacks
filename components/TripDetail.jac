import from "@jac/runtime" { Link, useParams }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" {
    ArrowRight01Icon, Airplane01Icon, Hotel01Icon, Restaurant01Icon, Ticket01Icon,
    Car01Icon, Tick02Icon, AiBrain01Icon, Wallet01Icon, SparklesIcon, Location01Icon
}
import from .ui.button { Button }
import from .ui.card { Card, CardContent, CardHeader, CardTitle, CardDescription }
import from .ui.badge { Badge }
import from .ui.progress { Progress }
import from .ui.skeleton { Skeleton }
import from "sonner" { toast }
import from ..lib.session { get_session_id }
import from ..lib.format { money, hour_label }
import from ..lib.speech { play_speech }
sv import from ..services.trips { get_trip, book_trip, TripView, ItemView, ActionView }
sv import from ..services.voice { speak_text, SpeechResult }

def kind_icon(kind: str) -> any {
    if kind == "FLIGHT" { return Airplane01Icon; }
    if kind == "HOTEL" { return Hotel01Icon; }
    if kind == "RESTAURANT" { return Restaurant01Icon; }
    if kind == "TRANSIT" { return Car01Icon; }
    return Ticket01Icon;
}

def agent_icon(agent: str) -> any {
    if agent == "MEMORY" { return AiBrain01Icon; }
    if agent == "FINANCIAL" { return Wallet01Icon; }
    if agent == "EXECUTION" { return Tick02Icon; }
    return SparklesIcon;
}

def:pub AgentTrace(actions: list[ActionView]) -> JsxElement {
    return <Card className="shadow-sm">
        <CardHeader>
            <CardTitle>Agent decision trace</CardTitle>
            <CardDescription>Every agent step, with Backboard memory reads and writes highlighted.</CardDescription>
        </CardHeader>
        <CardContent>
            <ol className="relative flex flex-col gap-4 border-l border-border pl-6">
                {for a in actions {
                    <li key={a.id} className="relative">
                        <span className={"absolute -left-[37px] top-0 flex size-7 items-center justify-center rounded-full ring-4 ring-card " + ("bg-primary text-primary-foreground" if a.agent == "MEMORY" else "bg-muted text-muted-foreground")}>
                            <HugeiconsIcon icon={agent_icon(a.agent)} strokeWidth={2} className="size-3.5" />
                        </span>
                        <div className={"flex flex-col gap-1 rounded-lg pt-2 pb-2 pl-3 pr-3 " + ("bg-primary/10 ring-1 ring-primary/30" if a.agent == "MEMORY" else "")}>
                            <div className="flex flex-wrap items-center gap-2">
                                <span className="text-xs font-semibold tracking-wide">{a.agent}</span>
                                <span className="text-xs text-muted-foreground">{a.action.replace("_", " ")}</span>
                                {a.tool and <Badge variant="outline" className="text-[10px]">{a.tool}</Badge>}
                                <Badge variant={"destructive" if a.status == "FAILED" else "secondary"} className="text-[10px]">{a.status}</Badge>
                            </div>
                            <p className="text-sm leading-relaxed">{a.detail}</p>
                        </div>
                    </li>
                }}
            </ol>
        </CardContent>
    </Card>;
}

def:pub TripDetail() -> JsxElement {
    has trip: TripView | None = None,
        loading: bool = True,
        booking: bool = False,
        error: str = "";
    params = useParams();

    async def load() -> None {
        loading = True;
        error = "";
        try {
            trip = await get_trip(get_session_id(), params.id);
        } except Exception as e {
            error = "Could not load this trip. " + str(e);
        }
        loading = False;
    }

    async def book() -> None {
        if trip == None { return; }
        booking = True;
        try {
            updated: TripView = await book_trip(get_session_id(), trip.id);
            trip = updated;
            line = "All set. I booked " + str(len(updated.items)) + " reservations for your " + updated.title + ", totalling " + money(updated.total_cost) + ".";
            toast.success("Trip booked");
            try {
                speech: SpeechResult = await speak_text(line);
                play_speech(speech.audio_base64, speech.mime, line);
            } except Exception {
                play_speech("", "", line);
            }
        } except Exception as e {
            toast.error("Booking failed: " + str(e));
        }
        booking = False;
    }

    async can with entry { await load(); }

    if loading {
        return <div className="flex flex-col gap-4">
            <Skeleton className="h-10 w-72" />
            <div className="grid gap-6 lg:grid-cols-3">
                <Skeleton className="h-96 rounded-xl lg:col-span-2" />
                <Skeleton className="h-64 rounded-xl" />
            </div>
        </div>;
    }
    if error or trip == None or not trip.found {
        return <div className="flex flex-col items-start gap-3">
            <p className="text-sm text-destructive">{error or "Trip not found."}</p>
            <div className="flex gap-2">
                <Button variant="outline" size="sm" onClick={load}>Retry</Button>
                <Link to="/trips"><Button variant="ghost" size="sm">Back to trips</Button></Link>
            </div>
        </div>;
    }

    t: TripView = trip;
    days: list[int] = [];
    for it in t.items {
        if it.day not in days { days.append(it.day); }
    }
    pct = min(100, int(t.total_cost / t.budget * 100)) if t.budget > 0 else 0;
    over = t.budget > 0 and t.total_cost > t.budget;
    mem_count = len([a for a in t.actions if a.agent == "MEMORY"]);

    return <div className="flex flex-col gap-6">
        <Link to="/trips" className="flex w-fit items-center gap-1 text-sm text-muted-foreground hover:text-foreground">
            <HugeiconsIcon icon={ArrowRight01Icon} strokeWidth={2} className="size-4 rotate-180" />
            Trips
        </Link>
        <div className="flex flex-wrap items-end justify-between gap-4">
            <div className="flex flex-col gap-1">
                <div className="flex items-center gap-2">
                    <h1 className="text-2xl font-semibold tracking-tight">{t.title}</h1>
                    <Badge variant={"default" if t.status == "BOOKED" else "secondary"}>{t.status}</Badge>
                </div>
                <p className="flex items-center gap-1 text-sm text-muted-foreground">
                    <HugeiconsIcon icon={Location01Icon} strokeWidth={2} className="size-4" />
                    {t.destination + " · " + str(t.days) + " days"}
                </p>
            </div>
            <Button size="lg" className="shadow-sm" disabled={booking or t.status == "BOOKED"} onClick={book}>
                <HugeiconsIcon icon={Tick02Icon} strokeWidth={2} />
                {"Booked" if t.status == "BOOKED" else ("Booking..." if booking else "Book trip")}
            </Button>
        </div>
        <div className="grid gap-6 lg:grid-cols-3">
            <div className="flex flex-col gap-6 lg:col-span-2">
                <Card className="shadow-sm">
                    <CardHeader>
                        <CardTitle>Planner summary</CardTitle>
                        <CardDescription>{"Request: " + t.prompt}</CardDescription>
                    </CardHeader>
                    <CardContent><p className="text-sm leading-relaxed">{t.summary}</p></CardContent>
                </Card>
                {for d in days {
                    <Card key={"day" + str(d)} className="shadow-sm">
                        <CardHeader><CardTitle>{"Day " + str(d + 1)}</CardTitle></CardHeader>
                        <CardContent className="flex flex-col gap-3">
                            {for it in t.items {
                                if it.day == d {
                                    <div key={it.id} className="flex items-start gap-3 rounded-lg border bg-card pt-3 pb-3 pl-3 pr-3">
                                        <div className="flex size-9 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary">
                                            <HugeiconsIcon icon={kind_icon(it.kind)} strokeWidth={2} className="size-4" />
                                        </div>
                                        <div className="flex min-w-0 flex-1 flex-col gap-0.5">
                                            <div className="flex flex-wrap items-center gap-2">
                                                <span className="font-medium">{it.title}</span>
                                                {it.status == "BOOKED" and <Badge variant="outline" className="text-[10px]">{"Booked " + it.confirmation}</Badge>}
                                            </div>
                                            <span className="text-xs text-muted-foreground">{hour_label(it.hour) + " · " + it.location}</span>
                                            {it.notes and <span className="text-sm text-muted-foreground">{it.notes}</span>}
                                        </div>
                                        <span className="text-sm font-medium tabular-nums">{money(it.price)}</span>
                                    </div>
                                }
                            }}
                        </CardContent>
                    </Card>
                }}
            </div>
            <div className="flex flex-col gap-6">
                <Card className="shadow-sm">
                    <CardHeader>
                        <CardTitle>Budget</CardTitle>
                        <CardDescription>Checked by the financial agent</CardDescription>
                    </CardHeader>
                    <CardContent className="flex flex-col gap-3">
                        <div className="flex items-baseline justify-between">
                            <span className="text-3xl font-semibold tracking-tight tabular-nums">{money(t.total_cost)}</span>
                            <span className="text-sm text-muted-foreground tabular-nums">{"of " + money(t.budget)}</span>
                        </div>
                        <Progress value={pct} />
                        <p className={"text-sm font-medium " + ("text-rose-600 dark:text-rose-400" if over else "text-emerald-600 dark:text-emerald-400")}>
                            {("Over budget by " + money(t.total_cost - t.budget)) if over else ("Within budget, " + money(t.budget - t.total_cost) + " to spare")}
                        </p>
                    </CardContent>
                </Card>
                <Card className="shadow-sm">
                    <CardHeader>
                        <CardTitle>Traveler memory</CardTitle>
                        <CardDescription>{"Backboard assistant, memory Auto" if t.memory_mode == "backboard" else "Local memory (add BACKBOARD_API_KEY to enable Backboard)"}</CardDescription>
                    </CardHeader>
                    <CardContent className="flex items-center gap-3">
                        <div className="flex size-9 items-center justify-center rounded-lg bg-primary/10 text-primary"><HugeiconsIcon icon={AiBrain01Icon} strokeWidth={2} className="size-4" /></div>
                        <span className="text-sm">{str(mem_count) + " memory events on this trip"}</span>
                    </CardContent>
                </Card>
                <AgentTrace actions={t.actions} />
            </div>
        </div>
    </div>;
}
