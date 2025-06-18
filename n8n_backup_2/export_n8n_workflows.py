import sqlite3
import json
import os
import re

def safe_filename(name):
    # Remove unsafe characters for filenames
    return re.sub(r'[^a-zA-Z0-9_-]', '_', name)[:50]

def export_workflows(sqlite_path, output_dir):
    os.makedirs(output_dir, exist_ok=True)
    conn = sqlite3.connect(sqlite_path)
    cursor = conn.cursor()
    cursor.execute("""
        SELECT id, name, nodes, connections, settings, staticData, pinData
        FROM workflow_entity
    """)
    for row in cursor.fetchall():
        workflow_id, name, nodes, connections, settings, staticData, pinData = row
        workflow_json = {
            "id": workflow_id,
            "name": name,
            "nodes": json.loads(nodes) if nodes else [],
            "connections": json.loads(connections) if connections else {},
            "settings": json.loads(settings) if settings else {},
            "staticData": json.loads(staticData) if staticData else None,
            "pinData": json.loads(pinData) if pinData else None,
        }
        filename = f"{safe_filename(name)}_{workflow_id}.json"
        filepath = os.path.join(output_dir, filename)
        with open(filepath, "w", encoding="utf-8") as f:
            json.dump(workflow_json, f, indent=2)
        print(f"Exported: {filepath}")
    conn.close()

if __name__ == "__main__":
    # Update these paths as needed
    SQLITE_PATH = r"C:\Users\Username\iCloudDrive\Documents\jerry-dev\github\local-llama-wsl2-server\n8n_backup_2\database.sqlite"
    OUTPUT_DIR = "exported_workflows"
    export_workflows(SQLITE_PATH, OUTPUT_DIR)