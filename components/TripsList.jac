import from "@jac/runtime" { Link, useNavigate }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { PlusSignIcon, Airplane01Icon, Location01Icon, Calendar03Icon, AiBrain01Icon, ArrowUpRight01Icon, Clock01Icon, SparklesIcon }
import from .ui.button { Button }
import from .ui.card { Card, CardContent, CardHeader, CardTitle, CardDescription }
import from .ui.badge { Badge }
import from .ui.skeleton { Skeleton }
import from .ui.empty { Empty, EmptyHeader, EmptyMedia, EmptyTitle, EmptyDescription, EmptyContent }
import from ..lib.session { get_session_id }
import from ..lib.format { money }
sv import from ..services.trips { list_trips, TripSummary }

def:pub TripsList() -> JsxElement {
    has trips: list[TripSummary] = [],
        loading: bool = True,
        error: str = "";
    navigate = useNavigate();

    async def load() -> None {
        loading = True;
        error = "";
        try {
            trips = await list_trips(get_session_id());
        } except Exception as e {
            error = "Could not load the travel graph. " + str(e);
        }
        loading = False;
    }

    async can with entry { await load(); }

    return <div className="flex flex-col gap-6">
        <div className="flex flex-wrap items-end justify-between gap-4">
            <div className="flex flex-col gap-1">
                <p className="text-[10px] font-semibold uppercase tracking-[0.22em] text-primary">WAYPORT · LIVE GRAPH</p>
                <h1 className="max-w-3xl text-3xl font-semibold leading-tight tracking-tight md:text-4xl">Nobody should spend a week booking a three-day offsite.</h1>
                <p className="max-w-2xl text-sm text-muted-foreground">Three inputs from your team. Wayport prices everyone, plans around policy, and brings the exceptions back to you.</p>
            </div>
            <Button className="shadow-sm" onClick={lambda { navigate("/trips/new"); }}>
                <HugeiconsIcon icon={PlusSignIcon} strokeWidth={2} />
                Plan a trip
            </Button>
        </div>
        {error and <div className="flex items-center gap-3 text-sm text-destructive"><span>{error}</span><Button variant="outline" size="sm" onClick={load}>Retry</Button></div>}
        {loading and <div className="grid gap-4 lg:grid-cols-3"><Skeleton className="h-80 rounded-xl lg:col-span-2" /><Skeleton className="h-80 rounded-xl" /></div>}
        {(not loading and not error and len(trips) == 0) and <Empty className="border border-dashed bg-card pt-12 pb-12">
            <EmptyHeader>
                <EmptyMedia variant="icon"><HugeiconsIcon icon={Airplane01Icon} strokeWidth={2} /></EmptyMedia>
                <EmptyTitle>Travel graph is waiting</EmptyTitle>
                <EmptyDescription>Start with a company trip. Your planner, traveler memory and finance agents will coordinate the details.</EmptyDescription>
            </EmptyHeader>
            <EmptyContent><Button onClick={lambda { navigate("/trips/new"); }}>Open AI Concierge</Button></EmptyContent>
        </Empty>}
        {(not loading and len(trips) > 0) and <div className="grid gap-5 xl:grid-cols-5">
            <Card className="overflow-hidden border-border/80 bg-card/80 shadow-sm xl:col-span-3">
                <CardHeader className="flex flex-row items-start justify-between gap-3 border-b border-border/70 pb-4">
                    <div className="flex flex-col gap-1"><CardTitle>Travel Graph</CardTitle><CardDescription>Active routes and company itineraries</CardDescription></div>
                    <Badge variant="outline" className="gap-1.5"><span className="size-1.5 rounded-full bg-primary" />{str(len(trips)) + " trips"}</Badge>
                </CardHeader>
                <CardContent className="p-0">
                    <div className="relative min-h-[390px] overflow-hidden bg-[radial-gradient(ellipse_at_50%_48%,oklch(0.24_0.04_190),oklch(0.12_0.02_255)_72%)]">
                        <div className="absolute inset-0 opacity-40" style={{"backgroundImage":"linear-gradient(oklch(1 0 0 / 5%) 1px, transparent 1px), linear-gradient(90deg, oklch(1 0 0 / 5%) 1px, transparent 1px)","backgroundSize":"42px 42px"}} />
                        <svg className="absolute inset-0 size-full" viewBox="0 0 800 420" preserveAspectRatio="xMidYMid slice" aria-label="Stylized travel graph map">
                            <path d="M-20 105 C75 52 127 96 180 77 S285 40 326 94 S418 140 463 101 S557 55 599 102 S704 144 835 83 L835 450 L-20 450Z" fill="oklch(0.3 0.04 190 / 18%)" stroke="oklch(0.7 0.1 185 / 22%)" stroke-width="1" />
                            <path d="M20 260 C132 204 198 284 300 230 S452 192 538 259 S690 314 812 221" fill="none" stroke="oklch(0.72 0.13 181 / 65%)" stroke-width="2" stroke-dasharray="5 8" />
                            <path d="M90 360 C170 304 270 342 353 287 S526 321 610 270 S721 256 795 294" fill="none" stroke="oklch(0.72 0.13 181 / 35%)" stroke-width="1.5" stroke-dasharray="3 8" />
                            <circle cx="300" cy="230" r="15" fill="oklch(0.72 0.13 181 / 13%)" /><circle cx="300" cy="230" r="6" fill="oklch(0.72 0.13 181)" />
                            <circle cx="538" cy="259" r="12" fill="oklch(0.72 0.13 181 / 13%)" /><circle cx="538" cy="259" r="5" fill="oklch(0.72 0.13 181)" />
                            <circle cx="610" cy="270" r="10" fill="oklch(0.72 0.13 181 / 13%)" /><circle cx="610" cy="270" r="4" fill="oklch(0.72 0.13 181)" />
                        </svg>
                        <div className="absolute left-[35%] top-[47%] rounded-md border border-primary/30 bg-background/90 px-2.5 py-1.5 text-[10px] shadow-lg backdrop-blur"><span className="font-semibold">LISBON</span><span className="ml-2 text-muted-foreground">Team offsite</span></div>
                        <div className="absolute right-[13%] top-[57%] rounded-md border border-border bg-background/85 px-2 py-1 text-[10px] text-muted-foreground shadow backdrop-blur">3 planned routes</div>
                        <div className="absolute bottom-4 left-4 flex items-center gap-2 rounded-md border border-border bg-background/80 px-3 py-2 text-[10px] text-muted-foreground backdrop-blur"><span className="size-1.5 rounded-full bg-primary" /> ROUTE GRAPH <span className="mx-1 text-border">|</span> AGENT PLANNED</div>
                    </div>
                </CardContent>
            </Card>
            <Card className="border-border/80 bg-card/80 shadow-sm xl:col-span-2">
                <CardHeader className="flex flex-row items-center justify-between gap-3">
                    <div className="flex flex-col gap-1"><CardTitle>Trip operations</CardTitle><CardDescription>Recent plans and agent activity</CardDescription></div>
                    <Button variant="ghost" size="sm" onClick={load}>Refresh</Button>
                </CardHeader>
                <CardContent className="flex flex-col gap-3">
                    {for t in trips {
                        <Link key={t.id} to={"/trips/" + t.id} className="block">
                            <div className="rounded-xl border border-border/80 bg-background/60 p-4 transition-all hover:border-primary/40 hover:bg-muted/40">
                                <div className="flex items-start justify-between gap-3">
                                    <div className="flex min-w-0 flex-col gap-1">
                                        <span className="text-[10px] font-semibold uppercase tracking-[0.16em] text-primary">{t.destination}</span>
                                        <span className="truncate text-base font-semibold">{t.title}</span>
                                    </div>
                                    <Badge variant={"default" if t.status == "BOOKED" else "secondary"}>{t.status}</Badge>
                                </div>
                                <div className="mt-4 flex flex-wrap items-center justify-between gap-3 border-t border-border/70 pt-3">
                                    <div className="flex flex-wrap items-center gap-3 text-xs text-muted-foreground">
                                        <span className="flex items-center gap-1"><HugeiconsIcon icon={Calendar03Icon} strokeWidth={2} className="size-3.5" />{str(t.days) + " days"}</span>
                                        <span className="flex items-center gap-1"><HugeiconsIcon icon={AiBrain01Icon} strokeWidth={2} className="size-3.5" />{"Backboard" if t.memory_mode == "backboard" else "Memory"}</span>
                                    </div>
                                    <span className="flex items-center gap-1 text-sm font-semibold tabular-nums">{money(t.total_cost)}<HugeiconsIcon icon={ArrowUpRight01Icon} strokeWidth={2} className="size-3.5 text-primary" /></span>
                                </div>
                            </div>
                        </Link>
                    }}
                    <div className="flex items-center gap-2 pt-1 text-xs text-muted-foreground"><HugeiconsIcon icon={Clock01Icon} strokeWidth={2} className="size-3.5" /><span>Agent traces live inside each trip workspace.</span></div>
                    <Link to="/memory" className="flex items-center gap-2 rounded-lg border border-primary/20 bg-primary/5 p-3 text-xs text-primary"><HugeiconsIcon icon={SparklesIcon} strokeWidth={2} className="size-4" /><span>Traveler preferences are shared across trips</span></Link>
                </CardContent>
            </Card>
        </div>}
    </div>;
}
