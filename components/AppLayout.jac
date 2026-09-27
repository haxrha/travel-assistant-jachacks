import from "@jac/runtime" { Link, useLocation, Outlet }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { Airplane01Icon, Folder01Icon, Mic01Icon, AiBrain01Icon }
import from .ui.sidebar {
    SidebarProvider, Sidebar, SidebarHeader, SidebarContent, SidebarFooter,
    SidebarGroup, SidebarGroupLabel, SidebarMenu, SidebarMenuItem,
    SidebarMenuButton, SidebarInset, SidebarTrigger
}
import from .ui.separator { Separator }
import from .ui.sonner_toast { Toaster }

glob NAV: list[dict] = [
    {"label": "Trips", "to": "/trips", "icon": Folder01Icon},
    {"label": "Plan by voice", "to": "/trips/new", "icon": Mic01Icon},
    {"label": "Traveler memory", "to": "/memory", "icon": AiBrain01Icon}
];

def:pub BrandMark(inverted: bool = False) -> JsxElement {
    tile = "bg-primary-foreground/15 text-primary-foreground" if inverted else "bg-primary text-primary-foreground shadow-sm";
    return <div className="flex items-center gap-2.5">
        <div className={"flex size-8 items-center justify-center rounded-lg " + tile}>
            <HugeiconsIcon icon={Airplane01Icon} strokeWidth={2} className="size-4" />
        </div>
        <span className="text-base font-semibold tracking-tight">WAYPORT</span>
    </div>;
}

def:pub AppLayout() -> JsxElement {
    path = useLocation().pathname;
    title = "Trips";
    for item in NAV {
        if path == item["to"] { title = item["label"]; }
    }
    if path.startswith("/trips/") and path != "/trips/new" { title = "Trip"; }
    return <SidebarProvider>
        <Sidebar variant="inset">
            <SidebarHeader><div className="pt-1 pb-1 pl-2 pr-2"><BrandMark /></div></SidebarHeader>
            <SidebarContent>
                <SidebarGroup>
                    <SidebarGroupLabel>Agents</SidebarGroupLabel>
                    <SidebarMenu>
                        {for item in NAV {
                            <SidebarMenuItem key={item["to"]}>
                                <SidebarMenuButton asChild={True} isActive={path == item["to"]}>
                                    <Link to={item["to"]}>
                                        <HugeiconsIcon icon={item["icon"]} strokeWidth={2} />
                                        <span>{item["label"]}</span>
                                    </Link>
                                </SidebarMenuButton>
                            </SidebarMenuItem>
                        }}
                    </SidebarMenu>
                </SidebarGroup>
            </SidebarContent>
            <SidebarFooter>
                <div className="rounded-lg bg-sidebar-accent/60 pt-3 pb-3 pl-3 pr-3 text-xs text-muted-foreground">
                    <p className="font-medium text-foreground">Demo traveler</p>
                    <p>Memory powered by Backboard, voice by ElevenLabs.</p>
                </div>
            </SidebarFooter>
        </Sidebar>
        <SidebarInset>
            <header className="flex h-14 shrink-0 items-center gap-2 border-b pl-4 pr-4">
                <SidebarTrigger />
                <Separator orientation="vertical" className="mr-2 h-4" />
                <span className="text-sm font-medium">{title}</span>
            </header>
            <main className="flex flex-1 flex-col gap-6 pt-6 pb-8 pl-4 pr-4 md:pl-8 md:pr-8 animate-in fade-in slide-in-from-bottom-1 duration-500">
                <Outlet />
            </main>
        </SidebarInset>
        <Toaster />
    </SidebarProvider>;
}
