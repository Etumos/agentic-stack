#!/usr/bin/env python3
"""
Initialize/reset daily cron budget.
Runs once per day via launchd or on-demand.
"""
import json
from pathlib import Path
from datetime import datetime, timezone

def init_budget():
    """Initialize or reset daily budget file."""
    budget_file = Path.home() / ".claude" / "agentic-stack" / "daily-budget.json"
    budget_file.parent.mkdir(parents=True, exist_ok=True)

    today = datetime.now(timezone.utc).date().isoformat()

    # Check if file exists and is valid
    if budget_file.exists():
        try:
            data = json.loads(budget_file.read_text())
            # If date matches, no reset needed
            if data.get("date") == today:
                print(f"✓ Budget initialized: {data['tokens_used_today']}/{data['daily_token_ceiling']} tokens used")
                return True
            # If date changed, reset counter
        except json.JSONDecodeError:
            print(f"⚠ Corrupted budget file, resetting")

    # Create or reset budget
    budget_data = {
        "daily_token_ceiling": 100000,
        "tokens_used_today": 0,
        "date": today,
        "initialized_at": datetime.now(timezone.utc).isoformat(),
    }

    budget_file.write_text(json.dumps(budget_data, indent=2))
    print(f"✓ Budget initialized for {today}: {budget_data['daily_token_ceiling']} token ceiling")
    return True

if __name__ == "__main__":
    init_budget()
