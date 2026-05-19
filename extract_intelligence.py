import sys
import os
import sqlite3
import re
from pypdf import PdfReader

# 1. Database Setup (SQL)
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "data", "documents.db")

def init_database():
    """Creates the SQLite database and tables using raw SQL queries."""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Table to log every file ingestion attempt
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS file_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            filename TEXT NOT NULL,
            processed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            status TEXT NOT NULL
        )
    """)
    
    # Table to store critical legal risks found in the documents
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS compliance_alerts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            log_id INTEGER,
            clause_type TEXT NOT NULL,
            snippet TEXT NOT NULL,
            FOREIGN KEY (log_id) REFERENCES file_logs(id)
        )
    """)
    conn.commit()
    conn.close()

# 2. Document Analysis Engine (NLP / Regex)
def analyze_pdf(file_path, filename):
    """Reads the PDF, scans for risk keywords, and saves results to the SQL DB."""
    init_database()
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Insert initial log into database (SQL)
    cursor.execute("INSERT INTO file_logs (filename, status) VALUES (?, ?)", (filename, "PROCESSING"))
    log_id = cursor.lastrowid
    conn.commit()

    try:
        # Extract text from PDF
        reader = PdfReader(file_path)
        full_text = ""
        for page in reader.pages:
            full_text += page.extract_text() or ""
            
        # Define high-risk patterns to look for in contracts/documents
        risk_patterns = {
            "CONFIDENTIALITY": r"(confidencial|segredo industrial|quebra de sigilo)",
            "FINANCIAL_PENALTY": r"(multa|rescis[ão|o]|juros|penalidade)",
            "COMPLIANCE_LGPD": r"(lgpd|dados pessoais|privacidade)"
        }
        
        alerts_found = 0
        # Scan text line by line to find matches and grab context snippets
        for clause_type, pattern in risk_patterns.items():
            matches = re.finditer(pattern, full_text, re.IGNORECASE)
            for match in matches:
                # Grab a snippet of 60 characters around the keyword for context
                start = max(0, match.start() - 20)
                end = min(len(full_text), match.end() + 40)
                snippet = full_text[start:end].replace("\n", " ").strip()
                
                # Save the alert into the database (SQL)
                cursor.execute(
                    "INSERT INTO compliance_alerts (log_id, clause_type, snippet) VALUES (?, ?, ?)",
                    (log_id, clause_type, f"...{snippet}...")
                )
                alerts_found += 1
                
        # Update file log status based on findings
        final_status = "ALERT_TRIGGERED" if alerts_found > 0 else "CLEAN"
        cursor.execute("UPDATE file_logs SET status = ? WHERE id = ?", (final_status, log_id))
        conn.commit()
        
        print(f"[PYTHON INFO] Analysis complete. Status: {final_status}. Alerts logged: {alerts_found}")
        sys.exit(0) # Exit Code 0 = Success for Shell Script
        
    except Exception as e:
        cursor.execute("UPDATE file_logs SET status = ? WHERE id = ?", ("FAILED", log_id))
        conn.commit()
        print(f"[PYTHON ERROR] Critical failure parsing PDF: {e}")
        sys.exit(1) # Exit Code 1 = Failure for Shell Script
    finally:
        conn.close()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("[PYTHON ERROR] Missing file path argument.")
        sys.exit(1)
        
    target_file = sys.argv[1]
    file_name = os.path.basename(target_file)
    analyze_pdf(target_file, file_name)