"""WAYPORT travel graph: travelers, trips, itinerary items and the agent audit trail."""

import os;
import json;
import random;

# Accept the Gemini key under any common name (litellm reads GEMINI_API_KEY).
with entry {
    if not os.environ.get("GEMINI_API_KEY") {
        alt = os.environ.get("GOOGLE_API_KEY") or os.environ.get("GOOGLE_GENERATIVE_AI_API_KEY") or "";
        if alt { os.environ["GEMINI_API_KEY"] = alt; }
    }
}
import from datetime { datetime }
import from services.memory { backboard_enabled, create_assistant, send_memory_message, MemoryReply }

# ---------------- Graph ----------------
node Traveler {
    has session_id: str,
        name: str = "Demo traveler",
        assistant_id: str = "",
        facts: list[str] = [];
}

node Trip {
    has title: str = "",
        destination: str = "",
        prompt: str = "",
        days: int = 3,
        budget: float = 0.0,
        summary: str = "",
        status: str = "PLANNED",
        thread_id: str = "",
        memory_mode: str = "local",
        created_at: str = "";
}

node TripItem {
    has kind: str = "ACTIVITY",
        title: str = "",
        day: int = 0,
        hour: float = 9.0,
        location: str = "",
        price: float = 0.0,
        notes: str = "",
        status: str = "TENTATIVE",
        confirmation: str = "";
}

node AgentAction {
    has seq: int = 0,
        agent: str = "PLANNER",
        tool: str = "",
        action: str = "",
        detail: str = "",
        status: str = "INFO",
        created_at: str = "";
}

# ---------------- LLM planner types ----------------
obj PlanItem {
    has kind: str,
        title: str,
        day: int,
        hour: float,
        location: str,
        price: float,
        notes: str;
}
sem PlanItem.kind = "One of FLIGHT, HOTEL, RESTAURANT, ACTIVITY, TRANSIT.";
sem PlanItem.day = "0-indexed day of the trip.";
sem PlanItem.hour = "Start hour, 0-23.";
sem PlanItem.location = "A real geocodeable place name, e.g. 'Belem Tower, Lisbon'.";
sem PlanItem.price = "Realistic price in USD (hotel = total for the stay).";
sem PlanItem.notes = "One short tip, mention which remembered preference it satisfies if any.";

obj PlanDraft {
    has title: str,
        destination: str,
        days: int,
        budget: float,
        summary: str,
        items: list[PlanItem],
        learned_preferences: list[str];
}
sem PlanDraft.title = "Short trip title like 'Lisbon long weekend'.";
sem PlanDraft.budget = "Total budget in USD from the request, or a sensible estimate.";
sem PlanDraft.summary = "Two sentences; say explicitly which remembered traveler preferences were applied.";
sem PlanDraft.items = "Day-by-day itinerary: a flight on day 0, one hotel, meals and activities each day, no overlaps.";
sem PlanDraft.learned_preferences = "New durable traveler preferences stated in THIS request (seat, budget ceiling, diet, flight times, hotel style). Short phrases. Empty if none.";

def draft_plan(request: str, remembered: list[str]) -> PlanDraft by llm(temperature=0.4);
sem draft_plan = "You are the WAYPORT planner agent. Turn the travel request into a realistic, budget-aware itinerary that respects every remembered traveler preference.";
sem draft_plan.request = "The traveler's trip request (typed or spoken).";
sem draft_plan.remembered = "Facts remembered about this traveler from previous trips.";

# ---------------- View models ----------------
obj ItemView {
    has id: str, kind: str, title: str, day: int, hour: float, location: str,
        price: float, notes: str, status: str, confirmation: str;
}

obj ActionView {
    has id: str, seq: int, agent: str, tool: str, action: str, detail: str,
        status: str, created_at: str;
}

obj TripSummary {
    has id: str, title: str, destination: str, days: int, budget: float,
        total_cost: float, status: str, item_count: int, memory_mode: str,
        created_at: str;
}

obj TripView {
    has id: str = "", title: str = "", destination: str = "", prompt: str = "",
        days: int = 0, budget: float = 0.0, total_cost: float = 0.0,
        summary: str = "", status: str = "", memory_mode: str = "local",
        thread_id: str = "", items: list[ItemView] = [],
        actions: list[ActionView] = [], found: bool = False;
}

obj MemoryEvent {
    has trip_id: str, trip_title: str, action: str, detail: str, created_at: str;
}

obj MemoryInfo {
    has mode: str = "local", assistant_id: str = "", facts: list[str] = [],
        events: list[MemoryEvent] = [], trip_count: int = 0;
}

# ---------------- Internal helpers (bodies in trips.impl.jac) ----------------
def _now() -> str;
def _get_traveler(session_id: str) -> Traveler;
def _log(trip: Trip, agent: str, tool: str, action: str, detail: str, status: str) -> None;
def _trip_view(trip: Trip) -> TripView;
def _find_trip(traveler: Traveler, trip_id: str) -> Trip | None;
def _plan_with_backboard(traveler: Traveler, trip: Trip, request: str) -> PlanDraft | None;
def _financial_check(trip: Trip) -> float;

# ---------------- Endpoints ----------------
def:pub list_trips(session_id: str) -> list[TripSummary];
def:pub plan_trip(session_id: str, prompt: str) -> TripView;
def:pub get_trip(session_id: str, trip_id: str) -> TripView;
def:pub book_trip(session_id: str, trip_id: str) -> TripView;
def:pub get_memory(session_id: str) -> MemoryInfo;
