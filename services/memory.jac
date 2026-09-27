"""Backboard client: one assistant per traveler, one thread per trip, memory Auto."""

import os;
import json;
import urllib.request;

glob BACKBOARD_BASE: str = "https://app.backboard.io/api";

obj MemoryReply {
    has ok: bool = False,
        content: str = "",
        thread_id: str = "",
        retrieved: list[str] = [],
        operation_id: str = "",
        error: str = "";
}

def _key() -> str {
    return os.environ.get("BACKBOARD_API_KEY", "") or "";
}

def backboard_enabled() -> bool {
    return len(_key()) > 0;
}

def _post(path: str, payload: dict) -> dict {
    data = json.dumps(payload).encode("utf-8");
    req = urllib.request.Request(
        BACKBOARD_BASE + path,
        data=data,
        headers={"X-API-Key": _key(), "Content-Type": "application/json"},
        method="POST"
    );
    with urllib.request.urlopen(req, timeout=60) as resp {
        return json.loads(resp.read().decode("utf-8"));
    }
}

"""Create a Backboard assistant for a traveler; returns its id or empty string."""
def create_assistant(traveler_name: str, session_id: str) -> str {
    if not backboard_enabled() {
        return "";
    }
    try {
        res = _post(
            "/assistants",
            {
                "name": f"WAYPORT traveler {traveler_name} ({session_id[:8]})",
                "system_prompt": "You are the WAYPORT planner agent. You remember each traveler's preferences across every trip: seats, budgets, diets, flight times, hotel style. Always apply what you remember."
            }
        );
        return str(res.get("assistant_id", "") or res.get("id", "") or "");
    } except Exception as e {
        print(f"[backboard] create_assistant failed: {str(e)}");
        return "";
    }
}

def _memory_text(m: any) -> str {
    if isinstance(m, str) {
        return m;
    }
    if isinstance(m, dict) {
        return str(m.get("memory", "") or m.get("content", "") or m.get("text", "") or json.dumps(m));
    }
    return str(m);
}

"""Send a message into a (new) thread for this assistant with memory Auto."""
def send_memory_message(assistant_id: str, content: str, system_prompt: str) -> MemoryReply {
    if not backboard_enabled() or not assistant_id {
        return MemoryReply(ok=False, error="Backboard not configured");
    }
    try {
        res = _post(
            "/threads/messages",
            {
                "assistant_id": assistant_id,
                "content": content,
                "system_prompt": system_prompt,
                "stream": False,
                "memory": "Auto",
                "json_output": True
            }
        );
        raw = res.get("retrieved_memories", []) or [];
        mems: list[str] = [_memory_text(m) for m in raw];
        return MemoryReply(
            ok=True,
            content=str(res.get("content", "") or ""),
            thread_id=str(res.get("thread_id", "") or ""),
            retrieved=mems,
            operation_id=str(res.get("memory_operation_id", "") or "")
        );
    } except Exception as e {
        return MemoryReply(ok=False, error=str(e));
    }
}
