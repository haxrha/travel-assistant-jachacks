import from services.trips {
    list_trips, plan_trip, get_trip, book_trip, get_memory,
    TripSummary, TripView, ItemView, ActionView, MemoryInfo, MemoryEvent
}
import from services.voice { speak_text, SpeechResult }

import ".styles.global.css";
import from "@jac/runtime" { Router, Routes, Route, Navigate }
import from .components.AppLayout { AppLayout }
import from .components.TripsList { TripsList }
import from .components.NewTrip { NewTrip }
import from .components.TripDetail { TripDetail }
import from .components.MemoryView { MemoryView }

def:pub app() -> JsxElement {
    return <Router>
        <Routes>
            <Route element={<AppLayout />}>
                <Route path="/trips" element={<TripsList />} />
                <Route path="/trips/new" element={<NewTrip />} />
                <Route path="/trips/:id" element={<TripDetail />} />
                <Route path="/memory" element={<MemoryView />} />
            </Route>
            <Route path="*" element={<Navigate to="/trips" replace={True} />} />
        </Routes>
    </Router>;
}
