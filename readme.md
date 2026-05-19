# DocuWatch: Automated Document Ingestion & Compliance Pipeline

DocuWatch is a production-grade, multi-language automation pipeline designed for secure document ingestion, legal/financial compliance auditing, and structured database logging. 

By combining the low-level system efficiency of **Shell Script (Bash)**, the analytical intelligence of **Python**, and the persistent structure of **SQL (SQLite)**, this project replicates a real-world DevOps and Data Engineering infrastructure. It operates completely hands-free, monitoring directories, processing raw text, handling system-level errors, and cataloging results.

---

## 🏗️ Multi-Language Architecture & Workflow

The pipeline is decoupled into three specialized layers, where each technology handles what it does best:

```text
[ INPUT DIRECTORY ] ──(New PDF Detected)──> [ 1. BASH ORCHESTRATOR ]
                                                    │
                                         (Triage & Process Call)
                                                    │
                                                    ▼
[ SQL DATABASE ] <──(Execute INSERT)─────── [ 2. PYTHON ENGINE ]
                                                    │
                                            (Return Exit Code)
                                                    │
                                                    ▼
[ ARCHIVE / ERROR ] <──(Move File)────────── [ 3. BASH QUARANTINE ]

1. System Layer (Bash): Acts as a lightweight, continuous daemon monitoring the filesystem. It handles initial file triage, isolates files during processing, reads Python subprocess execution signals, and routes files to their final destinations.

2. Analysis Layer (Python): Involved strictly on-demand. It parses the physical binary structure of PDFs using pypdf, executes pattern-matching algorithms via Regular Expressions (regex) to detect compliance liabilities, and manages database state transitions.

3. Persistence Layer (SQL): A relational schema that maps data ingestion history and correlates documents to specific flagged compliance risks using foreign key constraints.

---

## 📊 Database Schema (SQL)
The persistence layer uses a relational structure to decouple operational logs from security audit details:

* file_logs: Tracks every file that enters the pipeline, timestamping the ingestion and assigning an operational state (PROCESSING, CLEAN, ALERT_TRIGGERED, FAILED).

* compliance_alerts: Stores targeted text snippets containing legal risks extracted dynamically from the PDFs, mapped back to the source log via a log_id Foreign Key.

---

# ⚙️ Operating System Error Handling
A core feature of DocuWatch is its resilient cross-language error handling. The Python engine communicates its runtime success or failure back to the operating system using standard POSIX exit codes:

* sys.exit(0) (Success): Signals the Bash script that the PDF was read and audited completely. Bash then securely moves the file to data/archive/.

* sys.exit(1) (Failure): Triggered by runtime anomalies (e.g., encrypted PDFs, corrupted buffers, or file-lock issues). Bash intercepts this error signal, stops the pipeline deterioration, logs a system warning, and moves the file to the data/error/ quarantine folder.

---

# Getting Started (WSL2 / Ubuntu / Linux)

1. Project Directory Cloning
Ensure your local Linux environment has the correct pipeline structure:

```
mkdir -p ~/DocuWatch/data/{input,processing,archive,error}
cd ~/DocuWatch
```

2. Dependencies Installation
Install the necessary Python package for binary text extraction:

```
pip3 install pypdf
```

3. Permissions Setup
Give execution permissions to the Shell script core:

```
chmod +x monitor.sh
```

4. Running the Daemon
Start the real-time folder monitoring:

```
./monitor.sh
```

# 📈 Expected Production Log Output

====================================================
 Starting DocuWatch Kernel...
 Monitoring folder: /home/user/DocuWatch/data/input
====================================================
[SHELL INFO] New PDF detected! Initiating triage...
[SHELL INFO] Moving contract_v4.pdf to processing queue...
[SHELL INFO] Invoking Python intelligence framework...

[PYTHON INFO] Analysis complete. Status: ALERT_TRIGGERED. Alerts logged: 3
[SHELL SUCCESS] Python processed file successfully. Archiving...
====================================================

# 🛠️ Technologies & Tools Used

* Bash / Shell Script - Linux directory event monitoring, polling logic, and POSIX exit code routing.

* Python 3 - Stream computing, binary file ingestion, and algorithmic regex pattern matching.

* SQL (SQLite 3) - Relational persistence, transactional atomicity, and schema constraint enforcement.

* VS Code + WSL2 Extension - Windows-integrated Linux development environment.