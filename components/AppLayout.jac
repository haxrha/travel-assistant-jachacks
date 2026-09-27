import from "@jac/runtime" { Link, useLocation, Outlet }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { Airplane01Icon, Folder01Icon, Mic01Icon, AiBrain01Icon, UserGroupIcon, DashboardSquare01Icon }
import from .ui.sonner_toast { Toaster }

glob NAV: list[dict] = [
    {"label": "Trips", "to": "/trips", "icon": Folder01Icon, "group": "TRIP"},
    {"label": "AI Concierge", "to": "/trips/new", "icon": Mic01Icon, "group": "TRIP"},
    {"label": "Travelers", "to": "/memory", "icon": UserGroupIcon, "group": "COMPANY"},
    {"label": "Traveler memory", "to": "/memory", "icon": AiBrain01Icon, "group": "YOU"}
];

def:pub BrandMark() -> JsxElement {
    return <div className="flex items-center gap-3">
        <span className="flex size-9 items-center justify-center rounded-[10px] bg-primary/15 text-primary ring-1 ring-primary/30">
            <HugeiconsIcon icon={Airplane01Icon} strokeWidth={2} className="size-5" />
        </span>
        <div className="flex flex-col">
            <span className="text-sm font-semibold tracking-[0.22em]">WAYPORT</span>
            <span className="text-[10px] uppercase tracking-[0.25em] text-muted-foreground">Travel OS</span>
        </div>
    </div>;
}

def:pub AppLayout() -> JsxElement {
    path = useLocation().pathname;
    title = "Trips";
    for item in NAV {
        if path == item["to"] { title = item["label"]; }
    }
    if path.startswith("/trips/") and path != "/trips/new" { title = "Trip detail"; }

    return <div className="flex min-h-screen bg-background text-foreground">
        <aside className="sticky top-0 flex h-screen w-[248px] shrink-0 flex-col border-r border-sidebar-border bg-sidebar text-sidebar-foreground">
            <div className="flex flex-col gap-4 border-b border-sidebar-border px-4 py-4">
                <Link to="/trips" className="w-fit"><BrandMark /></Link>
                <div className="flex items-center gap-2.5 rounded-lg border border-sidebar-border bg-sidebar-accent/40 px-3 py-2.5">
                    <span className="flex size-7 items-center justify-center rounded-md bg-primary/15 text-[10px] font-semibold text-primary">WL</span>
                    <div className="min-w-0 flex-1">
                        <p className="truncate text-xs font-medium">Wayport Labs</p>
                        <p className="text-[10px] text-muted-foreground">Company workspace</p>
                    </div>
                    <span className="text-xs text-muted-foreground">⌄</span>
                </div>
            </div>
            <nav className="flex-1 overflow-y-auto px-3 py-4">
                <p className="mb-2 px-2 text-[10px] font-semibold tracking-[0.18em] text-muted-foreground">TRIP</p>
                <div className="flex flex-col gap-1">
                    {for item in NAV {
                        if item["group"] == "TRIP" {
                            <Link key={item["to"]} to={item["to"]} className={"flex items-center gap-3 rounded-lg px-3 py-2 text-sm transition-colors " + ("bg-sidebar-accent text-sidebar-accent-foreground" if path == item["to"] else "text-muted-foreground hover:bg-sidebar-accent/60 hover:text-foreground")}>
                                <HugeiconsIcon icon={item["icon"]} strokeWidth={2} className="size-4" />
                                <span>{item["label"]}</span>
                            </Link>
                        }
                    }}
                </div>
                <p className="mb-2 mt-6 px-2 text-[10px] font-semibold tracking-[0.18em] text-muted-foreground">COMPANY</p>
                <Link to="/memory" className={"flex items-center gap-3 rounded-lg px-3 py-2 text-sm transition-colors " + ("bg-sidebar-accent text-sidebar-accent-foreground" if path == "/memory" else "text-muted-foreground hover:bg-sidebar-accent/60 hover:text-foreground")}>
                    <HugeiconsIcon icon={UserGroupIcon} strokeWidth={2} className="size-4" />
                    <span>Travelers & memory</span>
                </Link>
                <p className="mb-2 mt-6 px-2 text-[10px] font-semibold tracking-[0.18em] text-muted-foreground">YOU</p>
                <Link to="/memory" className="flex items-center gap-3 rounded-lg px-3 py-2 text-sm text-muted-foreground transition-colors hover:bg-sidebar-accent/60 hover:text-foreground">
                    <HugeiconsIcon icon={AiBrain01Icon} strokeWidth={2} className="size-4" />
                    <span>Traveler memory</span>
                </Link>
            </nav>
            <div className="border-t border-sidebar-border p-3">
                <div className="rounded-lg border border-sidebar-border bg-sidebar-accent/30 p-3">
                    <p className="text-xs font-medium">Your travel agents</p>
                    <p className="mt-1 text-[10px] leading-relaxed text-muted-foreground">Planner · Memory · Finance · Voice</p>
                    <div className="mt-2 flex items-center gap-1.5 text-[10px] text-muted-foreground"><span className="size-1.5 rounded-full bg-primary" />Workspace ready</div>
                </div>
            </div>
        </aside>
        <div className="flex min-w-0 flex-1 flex-col">
            <header className="flex h-14 shrink-0 items-center justify-between border-b border-border bg-background/90 px-5">
                <div className="flex items-center gap-2 text-sm">
                    <HugeiconsIcon icon={DashboardSquare01Icon} strokeWidth={2} className="size-4 text-primary" />
                    <span className="font-medium">{title}</span>
                </div>
                <span className="text-xs text-muted-foreground">WAYPORT LABS</span>
            </header>
            <main className="flex min-w-0 flex-1 flex-col gap-6 p-5 md:p-7">
                <Outlet />
            </main>
        </div>
        <Toaster />
    </div>;
}
