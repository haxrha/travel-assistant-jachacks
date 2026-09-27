impl _now -> str {
    return datetime.now().isoformat(timespec="seconds");
}

impl _get_traveler(session_id: str) -> Traveler {
    for t in [root -->][?:Traveler] {
        if t.session_id == session_id {
            return t;
        }
    }
    t = root ++> Traveler(session_id=session_id);
    return t;
}

impl _log(trip: Trip, agent: str, tool: str, action: str, detail: str, status: str) -> None {
    seq = len([trip -->][?:AgentAction]) + 1;
    trip ++> AgentAction(
        seq=seq, agent=agent, tool=tool, action=action, detail=detail,
        status=status, created_at=_now()
    );
}

impl _find_trip(traveler: Traveler, trip_id: str) -> Trip | None {
    for t in [traveler -->][?:Trip] {
        if jid(t) == trip_id {
            return t;
        }
    }
    return None;
}

impl _trip_view(trip: Trip) -> TripView {
    items = [
        ItemView(
            id=jid(i), kind=i.kind, title=i.title, day=i.day, hour=i.hour,
            location=i.location, price=i.price, notes=i.notes, status=i.status,
            confirmation=i.confirmation
        )
        for i in [trip -->][?:TripItem]
    ];
    items.sort(key=lambda (v: ItemView) { v.day * 100 + v.hour; });
    actions = [
        ActionView(
            id=jid(a), seq=a.seq, agent=a.agent, tool=a.tool, action=a.action,
            detail=a.detail, status=a.status, created_at=a.created_at
        )
        for a in [trip -->][?:AgentAction]
    ];
    actions.sort(key=lambda (v: ActionView) { v.seq; });
    total = sum([i.price for i in items]);
    return TripView(
        id=jid(trip), title=trip.title, destination=trip.destination,
        prompt=trip.prompt, days=trip.days, budget=trip.budget,
        total_cost=total, summary=trip.summary, status=trip.status,
        memory_mode=trip.memory_mode, thread_id=trip.thread_id, items=items,
        actions=actions,
        members=[{"name": m.name, "role": m.role, "preference": m.preference} for m in [trip -->][?:TripMember]],
        found=True
    );
}

impl _plan_with_backboard(traveler: Traveler, trip: Trip, request: str) -> PlanDraft | None {
    if not backboard_enabled() {
        return None;
    }
    if not traveler.assistant_id {
        traveler.assistant_id = create_assistant(traveler.name, traveler.session_id);
        if traveler.assistant_id {
            _log(trip, "MEMORY", "backboard", "assistant_created", f"Backboard assistant {traveler.assistant_id} created for this traveler", "EXECUTED");
        }
    }
    if not traveler.assistant_id {
        _log(trip, "MEMORY", "backboard", "assistant_failed", "Could not create a Backboard assistant, falling back to local memory", "FAILED");
        return None;
    }
    schema = "{\"title\": str, \"destination\": str, \"days\": int, \"budget\": number, \"summary\": str, \"learned_preferences\": [str], \"items\": [{\"kind\": \"FLIGHT|HOTEL|RESTAURANT|ACTIVITY|TRANSIT\", \"title\": str, \"day\": int, \"hour\": number, \"location\": str, \"price\": number, \"notes\": str}]}";
    sys = "You are the WAYPORT planner agent. Use everything you remember about this traveler (seats, budget ceilings, diet, flight times, hotel style) and say in the summary which remembered preferences you applied. Reply ONLY with a JSON object matching: " + schema;
    reply: MemoryReply = send_memory_message(traveler.assistant_id, request, sys);
    if not reply.ok {
        _log(trip, "MEMORY", "backboard", "memory_error", reply.error[:200], "FAILED");
        return None;
    }
    trip.thread_id = reply.thread_id;
    if len(reply.retrieved) > 0 {
        _log(trip, "MEMORY", "backboard", "memory_read", f"Recalled {len(reply.retrieved)} memories: " + "; ".join(reply.retrieved[:6]), "OK");
    } else {
        _log(trip, "MEMORY", "backboard", "memory_read", "No memories recalled yet for this traveler (new thread " + reply.thread_id[:10] + ")", "INFO");
    }
    _log(trip, "MEMORY", "backboard", "memory_write", "memory: Auto queued extraction from this request (operation " + (reply.operation_id or "n/a") + ")", "EXECUTED");
    try {
        text = reply.content.strip();
        start = text.find("{");
        end = text.rfind("}");
        d = json.loads(text[start:end + 1]);
        items: list[PlanItem] = [];
        for raw in (d.get("items", []) or []) {
            items.append(
                PlanItem(
                    kind=str(raw.get("kind", "ACTIVITY")).upper(),
                    title=str(raw.get("title", "")),
                    day=int(raw.get("day", 0) or 0),
                    hour=float(raw.get("hour", 9) or 9),
                    location=str(raw.get("location", "") or ""),
                    price=float(raw.get("price", 0) or 0),
                    notes=str(raw.get("notes", "") or "")
                )
            );
        }
        learned: list[str] = [str(x) for x in (d.get("learned_preferences", []) or [])];
        facts = list(reply.retrieved);
        for f in learned {
            if f not in facts {
                facts.append(f);
            }
        }
        traveler.facts = facts[:30];
        return PlanDraft(
            title=str(d.get("title", "") or ""),
            destination=str(d.get("destination", "") or ""),
            days=int(d.get("days", 3) or 3),
            budget=float(d.get("budget", 0) or 0),
            summary=str(d.get("summary", "") or ""),
            items=items,
            learned_preferences=learned
        );
    } except Exception as e {
        _log(trip, "PLANNER", "backboard", "parse_error", "Could not parse Backboard plan: " + str(e)[:120], "FAILED");
        return None;
    }
}

impl _financial_check(trip: Trip) -> float {
    items = [trip -->][?:TripItem];
    total = sum([i.price for i in items]);
    hotel = sum([i.price for i in items if i.kind == "HOTEL"]);
    nightly = hotel / max(trip.days, 1);
    if trip.budget > 0 and total > trip.budget {
        _log(trip, "FINANCIAL", "budget", "over_budget", f"Planned ${total:.0f} exceeds budget ${trip.budget:.0f}. Hotel runs ${nightly:.0f}/night; recommend a cheaper stay.", "PENDING_APPROVAL");
    } else {
        _log(trip, "FINANCIAL", "budget", "budget_ok", f"Planned ${total:.0f} within budget ${trip.budget:.0f}. Hotel ${nightly:.0f}/night.", "OK");
    }
    return total;
}

impl list_trips(session_id: str) -> list[TripSummary] {
    traveler = _get_traveler(session_id);
    out: list[TripSummary] = [];
    for t in [traveler -->][?:Trip] {
        items = [t -->][?:TripItem];
        out.append(
            TripSummary(
                id=jid(t), title=t.title, destination=t.destination, days=t.days,
                budget=t.budget, total_cost=sum([i.price for i in items]),
                status=t.status, item_count=len(items), memory_mode=t.memory_mode,
                created_at=t.created_at
            )
        );
    }
    out.sort(key=lambda (s: TripSummary) { s.created_at; }, reverse=True);
    return out;
}

impl plan_trip(session_id: str, prompt: str, members: list[dict]) -> TripView {
    traveler = _get_traveler(session_id);
    trip = traveler ++> Trip(prompt=prompt, created_at=_now(), title="Planning...");
    member_context = "";
    for member in members {
        name = str(member.get("name", "Traveler"));
        role = str(member.get("role", ""));
        preference = str(member.get("preference", ""));
        trip ++> TripMember(name=name, role=role, preference=preference);
        member_context += f"\n{name} ({role}): {preference}";
    }
    full_request = prompt + ("\nCompany travelers:" + member_context if member_context else "");
    _log(trip, "PLANNER", "intake", "request_received", prompt[:240], "INFO");

    draft = _plan_with_backboard(traveler, trip, full_request);
    if draft != None {
        trip.memory_mode = "backboard";
    } else {
        trip.memory_mode = "local";
        remembered = list(traveler.facts);
        if len(remembered) > 0 {
            _log(trip, "MEMORY", "local", "memory_read", f"Recalled {len(remembered)} traveler facts: " + "; ".join(remembered[:6]), "OK");
        } else {
            _log(trip, "MEMORY", "local", "memory_read", "No traveler facts stored yet", "INFO");
        }
        try {
            _apply_gemini_key();
            draft = draft_plan(full_request, remembered);
            _log(trip, "PLANNER", "gemini", "itinerary_drafted", f"Gemini drafted {len(draft.items)} items using the configured model", "OK");
        } except Exception as e {
            err = str(e);
            category = "provider_error";
            if "Missing Gemini API key" in err or "Missing credentials" in err { category = "missing_key"; }
            elif "AuthenticationError" in err or "401" in err or "403" in err or "invalid api key" in err.lower() { category = "invalid_key"; }
            elif "model" in err.lower() and ("not found" in err.lower() or "404" in err) { category = "model_error"; }
            _log(trip, "PLANNER", "gemini", category, "Gemini request failed (" + category + "). Server detected a key; check that GEMINI_API_KEY is a valid Google AI Studio Gemini API key. Model: gemini/gemini-2.5-flash. Provider detail: " + err[:220], "FAILED");
            draft = PlanDraft(
                title="Trip plan", destination="Your destination", days=3,
                budget=1500.0,
                summary="Fallback sample itinerary: the Gemini request reached the provider, but Google rejected the configured credential. Replace GEMINI_API_KEY with a valid Google AI Studio Gemini API key in Settings > Environment, save, restart, and try again.",
                items=[
                    PlanItem(kind="FLIGHT", title="Outbound flight", day=0, hour=9.0, location="Home airport", price=320.0, notes="Morning departure"),
                    PlanItem(kind="HOTEL", title="Central hotel", day=0, hour=15.0, location="City center", price=450.0, notes="3 nights"),
                    PlanItem(kind="RESTAURANT", title="Welcome dinner", day=0, hour=19.5, location="Old town", price=45.0, notes=""),
                    PlanItem(kind="ACTIVITY", title="Walking tour", day=1, hour=10.0, location="Historic district", price=25.0, notes=""),
                    PlanItem(kind="ACTIVITY", title="Museum visit", day=2, hour=11.0, location="National museum", price=20.0, notes="")
                ],
                learned_preferences=[]
            );
        }
        learned_now = (draft as PlanDraft).learned_preferences;
        new_facts = [f for f in learned_now if f not in traveler.facts];
        if len(new_facts) > 0 {
            traveler.facts = (traveler.facts + new_facts)[-30:];
            _log(trip, "MEMORY", "local", "memory_write", "Stored new traveler facts: " + "; ".join(new_facts), "EXECUTED");
        }
    }

    plan: PlanDraft = draft as PlanDraft;
    trip.title = plan.title or "Trip plan";
    trip.destination = plan.destination;
    trip.days = max(plan.days, 1);
    trip.budget = plan.budget;
    trip.summary = plan.summary;
    for it in plan.items {
        trip ++> TripItem(
            kind=it.kind, title=it.title, day=it.day, hour=it.hour,
            location=it.location, price=it.price, notes=it.notes
        );
    }
    _log(trip, "PLANNER", "graph", "itinerary_saved", f"{len(plan.items)} items written to the travel graph for {trip.destination}", "EXECUTED");
    _financial_check(trip);
    return _trip_view(trip);
}

impl get_trip(session_id: str, trip_id: str) -> TripView {
    traveler = _get_traveler(session_id);
    trip = _find_trip(traveler, trip_id);
    if trip == None {
        return TripView(found=False);
    }
    return _trip_view(trip);
}

impl book_trip(session_id: str, trip_id: str) -> TripView {
    traveler = _get_traveler(session_id);
    trip = _find_trip(traveler, trip_id);
    if trip == None {
        return TripView(found=False);
    }
    booked = 0;
    for i in [trip -->][?:TripItem] {
        if i.kind in ["FLIGHT", "HOTEL", "RESTAURANT", "ACTIVITY", "TRANSIT"] and i.status != "BOOKED" {
            i.status = "BOOKED";
            i.confirmation = "WP" + str(random.randint(100000, 999999));
            booked += 1;
            _log(trip, "EXECUTION", i.kind.lower(), "booked", f"{i.title} confirmed ({i.confirmation}) for ${i.price:.0f}", "EXECUTED");
        }
    }
    trip.status = "BOOKED";
    _log(trip, "EXECUTION", "booking", "trip_booked", f"{booked} reservations confirmed", "EXECUTED");
    return _trip_view(trip);
}

impl get_memory(session_id: str) -> MemoryInfo {
    traveler = _get_traveler(session_id);
    events: list[MemoryEvent] = [];
    trips = [traveler -->][?:Trip];
    for t in trips {
        for a in [t -->][?:AgentAction] {
            if a.agent == "MEMORY" {
                events.append(
                    MemoryEvent(trip_id=jid(t), trip_title=t.title, action=a.action, detail=a.detail, created_at=a.created_at)
                );
            }
        }
    }
    events.sort(key=lambda (e: MemoryEvent) { e.created_at; }, reverse=True);
    return MemoryInfo(
        mode="backboard" if backboard_enabled() else "local",
        assistant_id=traveler.assistant_id, facts=list(traveler.facts),
        events=events[:50], trip_count=len(trips)
    );
}
