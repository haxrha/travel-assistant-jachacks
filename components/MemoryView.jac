import from "@jac/runtime" { Link, useNavigate }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { AiBrain01Icon, CheckmarkCircle02Icon, Folder01Icon }
import from .ui.button { Button }
import from .ui.card { Card, CardContent, CardHeader, CardTitle, CardDescription }
import from .ui.badge { Badge }
import from .ui.skeleton { Skeleton }
import from .ui.empty { Empty, EmptyHeader, EmptyMedia, EmptyTitle, EmptyDescription, EmptyContent }
import from ..lib.session { get_session_id }
sv import from ..services.trips { get_memory, MemoryInfo, MemoryEvent }

def:pub MemoryView() -> JsxElement {
    has info: MemoryInfo | None = None,
        loading: bool = True,
        error: str = "";
    navigate = useNavigate();

    async def load() -> None {
        loading = True;
        error = "";
        try {
            info = await get_memory(get_session_id());
        } except Exception as e {
            error = "Could not load memory. " + str(e);
        }
        loading = False;
    }

    async can with entry { await load(); }

    if loading {
        return <div className="grid gap-4 md:grid-cols-3">
            <Skeleton className="h-28 rounded-xl" /><Skeleton className="h-28 rounded-xl" /><Skeleton className="h-28 rounded-xl" />
        </div>;
    }
    if error or info == None {
        return <div className="flex items-center gap-3 text-sm text-destructive">
            <span>{error or "No memory data."}</span>
            <Button variant="outline" size="sm" onClick={load}>Retry</Button>
        </div>;
    }
    m: MemoryInfo = info;

    return <div className="flex flex-col gap-6">
        <div className="flex flex-col gap-1">
            <h1 className="text-2xl font-semibold tracking-tight">Traveler memory</h1>
            <p className="text-sm text-muted-foreground">What your planner agent has learned about you across every trip.</p>
        </div>
        <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
            <Card className="shadow-sm"><CardContent className="flex flex-col gap-2">
                <span className="text-sm text-muted-foreground">Memory provider</span>
                <span className="text-2xl font-semibold tracking-tight">{"Backboard" if m.mode == "backboard" else "Local"}</span>
                <span className="truncate text-xs text-muted-foreground">{("Assistant " + m.assistant_id) if m.assistant_id else ("Assistant created on first trip" if m.mode == "backboard" else "Add BACKBOARD_API_KEY in Settings")}</span>
            </CardContent></Card>
            <Card className="shadow-sm"><CardContent className="flex flex-col gap-2">
                <span className="text-sm text-muted-foreground">Remembered facts</span>
                <span className="text-3xl font-semibold tracking-tight tabular-nums">{str(len(m.facts))}</span>
            </CardContent></Card>
            <Card className="shadow-sm"><CardContent className="flex flex-col gap-2">
                <span className="text-sm text-muted-foreground">Trips planned</span>
                <span className="text-3xl font-semibold tracking-tight tabular-nums">{str(m.trip_count)}</span>
            </CardContent></Card>
        </div>
        <div className="grid grid-cols-1 gap-6 lg:grid-cols-5">
            <Card className="shadow-sm lg:col-span-2">
                <CardHeader>
                    <CardTitle>What it knows about you</CardTitle>
                    <CardDescription>Applied automatically to the next trip</CardDescription>
                </CardHeader>
                <CardContent>
                    {(len(m.facts) == 0) and <Empty className="border border-dashed pt-10 pb-10">
                        <EmptyHeader>
                            <EmptyMedia variant="icon"><HugeiconsIcon icon={AiBrain01Icon} strokeWidth={2} /></EmptyMedia>
                            <EmptyTitle>Nothing remembered yet</EmptyTitle>
                            <EmptyDescription>Mention a preference like "aisle seat" or "vegetarian" while planning.</EmptyDescription>
                        </EmptyHeader>
                        <EmptyContent><Button onClick={lambda { navigate("/trips/new"); }}>Plan a trip</Button></EmptyContent>
                    </Empty>}
                    <ul className="flex flex-col gap-2">
                        {for f in m.facts {
                            <li key={f} className="flex items-start gap-2 rounded-lg bg-muted/50 pt-2 pb-2 pl-3 pr-3 text-sm">
                                <HugeiconsIcon icon={CheckmarkCircle02Icon} strokeWidth={2} className="mt-0.5 size-4 shrink-0 text-primary" />
                                {f}
                            </li>
                        }}
                    </ul>
                </CardContent>
            </Card>
            <Card className="shadow-sm lg:col-span-3">
                <CardHeader>
                    <CardTitle>Memory activity</CardTitle>
                    <CardDescription>Reads and writes logged in each trip's audit trail</CardDescription>
                </CardHeader>
                <CardContent className="flex flex-col gap-3">
                    {(len(m.events) == 0) and <p className="text-sm text-muted-foreground">No memory activity yet.</p>}
                    {for e in m.events {
                        <div key={e.trip_id + e.created_at + e.action} className="flex flex-col gap-1 rounded-lg border pt-3 pb-3 pl-3 pr-3">
                            <div className="flex flex-wrap items-center gap-2">
                                <Badge variant={"default" if e.action == "memory_write" else "secondary"}>{e.action.replace("_", " ")}</Badge>
                                <Link to={"/trips/" + e.trip_id} className="flex items-center gap-1 text-xs font-medium hover:underline">
                                    <HugeiconsIcon icon={Folder01Icon} strokeWidth={2} className="size-3.5" />{e.trip_title}
                                </Link>
                                <span className="text-xs text-muted-foreground">{e.created_at.replace("T", " ")}</span>
                            </div>
                            <p className="text-sm leading-relaxed">{e.detail}</p>
                        </div>
                    }}
                </CardContent>
            </Card>
        </div>
    </div>;
}
