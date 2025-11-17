#!/usr/bin/env python3
"""OODA Loop Task Processor - Observe, Orient, Decide, Act"""
import json
from pathlib import Path

TASKS_FILE = Path("tasks.jsonl")
AGENT_TASKS = Path("/tmp/agent_tasks")

def observe():
    """Observe: Load pending tasks"""
    tasks = []
    for line in TASKS_FILE.read_text().splitlines():
        task = json.loads(line)
        if task["status"] == "pending":
            tasks.append(task)
    return tasks

def orient(tasks):
    """Orient: Check dependencies, prioritize"""
    done_ids = {json.loads(line)["id"] 
                for line in TASKS_FILE.read_text().splitlines()
                if json.loads(line)["status"] == "done"}
    
    ready = []
    for task in tasks:
        deps = task.get("deps", [])
        if all(d in done_ids for d in deps):
            ready.append(task)
    
    # Prioritize by phase: research → develop → test → evaluate
    phase_priority = {"research": 1, "develop": 2, "test": 3, "evaluate": 4}
    ready.sort(key=lambda t: phase_priority.get(t["phase"], 5))
    return ready

def decide(ready_tasks):
    """Decide: Select next task batch"""
    # Take up to 3 tasks that can run in parallel
    batch = ready_tasks[:3]
    return batch

def act(task_batch):
    """Act: Delegate to agents via file-based queue"""
    AGENT_TASKS.mkdir(exist_ok=True)
    
    for task in task_batch:
        agent = task.get("agent", "architect")
        task_file = AGENT_TASKS / f"{agent}.json"
        task_file.write_text(json.dumps({
            "task_id": task["id"],
            "task": task["task"],
            "phase": task["phase"]
        }, indent=2))
        print(f"✅ Delegated {task['id']} to {agent}: {task['task']}")

def main():
    print("🔄 OODA Loop: Observe → Orient → Decide → Act")
    
    # Observe
    pending = observe()
    print(f"📊 Observed: {len(pending)} pending tasks")
    
    # Orient
    ready = orient(pending)
    print(f"🎯 Oriented: {len(ready)} tasks ready (deps satisfied)")
    
    # Decide
    batch = decide(ready)
    print(f"🧠 Decided: Process batch of {len(batch)} tasks")
    
    # Act
    if batch:
        act(batch)
        print(f"🚀 Acted: {len(batch)} tasks delegated to agents")
    else:
        print("⏸️ No tasks ready - waiting for dependencies")

if __name__ == "__main__":
    main()
