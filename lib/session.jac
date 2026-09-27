"""Demo-mode traveler session id, persisted in localStorage (stands in for a Clerk user id)."""

cl def:pub get_session_id() -> str {
    sid = localStorage.getItem("wayport_session_id");
    if not sid {
        sid = "demo-" + str(Math.random()).replace("0.", "") + str(Date.now());
        localStorage.setItem("wayport_session_id", sid);
    }
    return sid;
}
