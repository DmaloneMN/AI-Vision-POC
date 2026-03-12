"""
WritePredictionActivity – Durable Activity Function
Persists prediction results to Azure SQL:
  - Inserts a row into dbo.ShelfReadings
  - Inserts rows into dbo.Predictions for each tag detected
"""

import logging
import os
import struct
from datetime import datetime, timezone
from typing import Any

import pyodbc

logger = logging.getLogger(__name__)


def main(payload: dict) -> dict:
    """Activity entry point.

    Args:
        payload: Dict with analysis results, store_id, shelf_id, blob_name, blob_url, timestamp.

    Returns:
        Dict with reading_id of the inserted ShelfReading row.
    """
    analysis: dict = payload.get("analysis", {})
    store_id: str  = payload.get("store_id", "unknown")
    shelf_id: str  = payload.get("shelf_id", "unknown")
    blob_name: str = payload.get("blob_name", "")
    blob_url: str  = payload.get("blob_url", "")
    timestamp: str = payload.get("timestamp", datetime.now(timezone.utc).isoformat())

    availability_score: float = analysis.get("availability_score", 0.0)
    filled_slots: int         = analysis.get("filled_slots", 0)
    empty_slots: int          = analysis.get("empty_slots", 0)
    predictions: list         = analysis.get("predictions", [])

    logger.info(
        "WritePredictionActivity: store_id=%s shelf_id=%s score=%.2f",
        store_id,
        shelf_id,
        availability_score,
    )

    conn_str = _build_connection_string()
    reading_id = None

    with pyodbc.connect(conn_str, timeout=30) as conn:
        cursor = conn.cursor()

        # Resolve integer IDs (create records if they don't exist)
        store_int_id = _get_or_create_store(cursor, store_id)
        shelf_int_id = _get_or_create_shelf(cursor, shelf_id, store_int_id)

        # Insert ShelfReading
        cursor.execute(
            """
            INSERT INTO dbo.ShelfReadings
                (ShelfId, StoreId, BlobName, BlobUrl, CapturedAt, ProcessedAt,
                 AvailabilityScore, FilledSlots, EmptySlots)
            OUTPUT INSERTED.ReadingId
            VALUES (?, ?, ?, ?, ?, GETUTCDATE(), ?, ?, ?)
            """,
            shelf_int_id,
            store_int_id,
            blob_name,
            blob_url,
            timestamp,
            availability_score,
            filled_slots,
            empty_slots,
        )
        row = cursor.fetchone()
        reading_id = row[0] if row else None

        # Insert Predictions
        for pred in predictions:
            bb = pred.get("bounding_box") or {}
            cursor.execute(
                """
                INSERT INTO dbo.Predictions
                    (ReadingId, TagName, Probability,
                     BoundingBoxLeft, BoundingBoxTop, BoundingBoxWidth, BoundingBoxHeight)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                reading_id,
                pred.get("tag", ""),
                pred.get("probability", 0.0),
                bb.get("left"),
                bb.get("top"),
                bb.get("width"),
                bb.get("height"),
            )

        conn.commit()

    logger.info("WritePredictionActivity: reading_id=%s inserted.", reading_id)
    return {"reading_id": reading_id}


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

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


def _get_or_create_store(cursor: pyodbc.Cursor, store_code: str) -> int:
    cursor.execute(
        "SELECT StoreId FROM dbo.Stores WHERE StoreCode = ?", store_code
    )
    row = cursor.fetchone()
    if row:
        return row[0]
    cursor.execute(
        "INSERT INTO dbo.Stores (StoreName, StoreCode) OUTPUT INSERTED.StoreId VALUES (?, ?)",
        store_code, store_code,
    )
    return cursor.fetchone()[0]


def _get_or_create_shelf(cursor: pyodbc.Cursor, shelf_code: str, store_id: int) -> int:
    cursor.execute(
        "SELECT ShelfId FROM dbo.Shelves WHERE ShelfCode = ? AND StoreId = ?",
        shelf_code, store_id,
    )
    row = cursor.fetchone()
    if row:
        return row[0]
    cursor.execute(
        """
        INSERT INTO dbo.Shelves (StoreId, ShelfCode, ShelfName)
        OUTPUT INSERTED.ShelfId
        VALUES (?, ?, ?)
        """,
        store_id, shelf_code, shelf_code,
    )
    return cursor.fetchone()[0]
