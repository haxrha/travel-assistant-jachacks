import from "@jac/runtime" { Link, useNavigate }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { PlusSignIcon, Airplane01Icon, Location01Icon, Calendar03Icon, AiBrain01Icon }
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
            error = "Could not load trips. " + str(e);
        }
        loading = False;
    }

    async can with entry { await load(); }

    return <div className="flex flex-col gap-6">
        <div className="flex flex-wrap items-end justify-between gap-4">
            <div className="flex flex-col gap-1">
                <h1 className="text-2xl font-semibold tracking-tight">Your trips</h1>
                <p className="text-sm text-muted-foreground">Every itinerary your planner, financial and booking agents have built, with the memory they carried across trips.</p>
            </div>
            <Button className="shadow-sm" onClick={lambda { navigate("/trips/new"); }}>
                <HugeiconsIcon icon={PlusSignIcon} strokeWidth={2} />
                New trip
            </Button>
        </div>
        {error and <div className="flex items-center gap-3 text-sm text-destructive">
            <span>{error}</span>
            <Button variant="outline" size="sm" onClick={load}>Retry</Button>
        </div>}
        {loading and <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            <Skeleton className="h-40 rounded-xl" />
            <Skeleton className="h-40 rounded-xl" />
            <Skeleton className="h-40 rounded-xl" />
        </div>}
        {(not loading and not error and len(trips) == 0) and <Empty className="border border-dashed bg-card pt-12 pb-12">
            <EmptyHeader>
                <EmptyMedia variant="icon"><HugeiconsIcon icon={Airplane01Icon} strokeWidth={2} /></EmptyMedia>
                <EmptyTitle>No trips yet</EmptyTitle>
                <EmptyDescription>Say or type where you want to go. Mention a preference like "aisle seat" and watch the next trip remember it.</EmptyDescription>
            </EmptyHeader>
            <EmptyContent><Button onClick={lambda { navigate("/trips/new"); }}>Plan your first trip</Button></EmptyContent>
        </Empty>}
        {(not loading and len(trips) > 0) and <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {for t in trips {
                <Link key={t.id} to={"/trips/" + t.id} className="block">
                    <Card className="h-full shadow-sm transition-all hover:-translate-y-0.5 hover:shadow-md">
                        <CardHeader className="flex flex-row items-start justify-between gap-3">
                            <div className="flex flex-col gap-1">
                                <CardTitle>{t.title}</CardTitle>
                                <CardDescription className="flex items-center gap-1">
                                    <HugeiconsIcon icon={Location01Icon} strokeWidth={2} className="size-3.5" />
                                    {t.destination}
                                </CardDescription>
                            </div>
                            <Badge variant={"default" if t.status == "BOOKED" else "secondary"}>{t.status}</Badge>
                        </CardHeader>
                        <CardContent className="flex flex-col gap-3">
                            <div className="flex items-baseline justify-between">
                                <span className="text-2xl font-semibold tracking-tight tabular-nums">{money(t.total_cost)}</span>
                                <span className="text-xs text-muted-foreground tabular-nums">{"of " + money(t.budget) + " budget"}</span>
                            </div>
                            <div className="flex flex-wrap items-center gap-3 text-xs text-muted-foreground">
                                <span className="flex items-center gap-1"><HugeiconsIcon icon={Calendar03Icon} strokeWidth={2} className="size-3.5" />{str(t.days) + (" day" if t.days == 1 else " days")}</span>
                                <span>{str(t.item_count) + " stops"}</span>
                                <span className="flex items-center gap-1"><HugeiconsIcon icon={AiBrain01Icon} strokeWidth={2} className="size-3.5" />{"Backboard memory" if t.memory_mode == "backboard" else "Local memory"}</span>
                            </div>
                        </CardContent>
                    </Card>
                </Link>
            }}
        </div>}
    </div>;
}
