"""
PersistAlertActivity – Durable Activity Function
Evaluates availability thresholds and inserts an Alert row into dbo.Alerts.

Thresholds:
  - Critical : availability_score < 50 %
  - Warning  : availability_score < 75 %
  - No alert : availability_score >= 75 %
"""

import logging
import os
from datetime import datetime, timezone

import pyodbc

logger = logging.getLogger(__name__)

CRITICAL_THRESHOLD = 50.0
WARNING_THRESHOLD  = 75.0


def main(payload: dict) -> dict:
    """Activity entry point.

    Args:
        payload: Dict with availability_score, store_id, shelf_id, reading_id.

    Returns:
        Dict with alert_created (bool), severity (str|None), alert_id (int|None).
    """
    availability_score: float = payload.get("availability_score", 100.0)
    store_id: str             = payload.get("store_id", "unknown")
    shelf_id: str             = payload.get("shelf_id", "unknown")
    reading_id: int | None    = payload.get("reading_id")

    severity = _determine_severity(availability_score)

    if severity is None:
        logger.info(
            "PersistAlertActivity: no alert needed. store_id=%s shelf_id=%s score=%.2f",
            store_id,
            shelf_id,
            availability_score,
        )
        return {"alert_created": False, "severity": None, "alert_id": None}

    logger.info(
        "PersistAlertActivity: creating %s alert. store_id=%s shelf_id=%s score=%.2f",
        severity,
        store_id,
        shelf_id,
        availability_score,
    )

    alert_id = _insert_alert(store_id, shelf_id, reading_id, severity, availability_score)

    return {
        "alert_created": True,
        "severity": severity,
        "alert_id": alert_id,
        "availability_score": availability_score,
        "store_id": store_id,
        "shelf_id": shelf_id,
    }


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _determine_severity(score: float) -> str | None:
    if score < CRITICAL_THRESHOLD:
        return "Critical"
    if score < WARNING_THRESHOLD:
        return "Warning"
    return None


def _build_connection_string() -> str:
    server   = os.environ["SQL_SERVER"]
    database = os.environ["SQL_DATABASE"]
    username = os.environ["SQL_USERNAME"]
    password = os.environ["SQL_PASSWORD"]
    return (
        f"DRIVER={{ODBC Driver 18 for SQL Server}};"
        f"SERVER={server};"
        f"DATABASE={database};"
        f"UID={username};"
        f"PWD={password};"
        "Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"
    )


def _insert_alert(
    store_code: str,
    shelf_code: str,
    reading_id: int | None,
    severity: str,
    availability_score: float,
) -> int:
    conn_str = _build_connection_string()
    message = (
        f"Shelf {shelf_code} in store {store_code} has availability score "
        f"{availability_score:.1f}% – severity: {severity}"
    )

    with pyodbc.connect(conn_str, timeout=30) as conn:
        cursor = conn.cursor()

        store_int_id = _get_store_id(cursor, store_code)
        shelf_int_id = _get_shelf_id(cursor, shelf_code, store_int_id)

        cursor.execute(
            """
            INSERT INTO dbo.Alerts
                (ShelfId, StoreId, ReadingId, Severity, AvailabilityScore, Message)
            OUTPUT INSERTED.AlertId
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            shelf_int_id,
            store_int_id,
            reading_id,
            severity,
            availability_score,
            message,
        )
        row = cursor.fetchone()
        alert_id = row[0] if row else None
        conn.commit()

    return alert_id


def _get_store_id(cursor: pyodbc.Cursor, store_code: str) -> int:
    cursor.execute("SELECT StoreId FROM dbo.Stores WHERE StoreCode = ?", store_code)
    row = cursor.fetchone()
    return row[0] if row else 0


def _get_shelf_id(cursor: pyodbc.Cursor, shelf_code: str, store_id: int) -> int:
    cursor.execute(
        "SELECT ShelfId FROM dbo.Shelves WHERE ShelfCode = ? AND StoreId = ?",
        shelf_code, store_id,
    )
    row = cursor.fetchone()
    return row[0] if row else 0
