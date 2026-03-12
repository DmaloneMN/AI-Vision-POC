"""
shelf_status – HTTP Triggered Function
Provides an HTTP GET/POST endpoint to query current shelf availability status.

Query parameters (GET) or JSON body (POST):
  - store_id  (optional): filter by store code
  - shelf_id  (optional): filter by shelf code

Returns JSON with store/shelf availability data and active alerts.
"""

import json
import logging
import os

import azure.functions as func
import pyodbc

logger = logging.getLogger(__name__)


def main(req: func.HttpRequest) -> func.HttpResponse:
    """HTTP trigger entry point.

    Args:
        req: The HTTP request object.

    Returns:
        HttpResponse with JSON payload.
    """
    store_id = req.params.get("store_id")
    shelf_id = req.params.get("shelf_id")

    if req.method == "POST":
        try:
            body = req.get_json()
            store_id = store_id or body.get("store_id")
            shelf_id = shelf_id or body.get("shelf_id")
        except ValueError:
            pass

    logger.info(
        "shelf_status: query store_id=%s shelf_id=%s", store_id, shelf_id
    )

    try:
        result = _query_shelf_status(store_id, shelf_id)
        return func.HttpResponse(
            json.dumps(result, default=str),
            mimetype="application/json",
            status_code=200,
        )
    except Exception as exc:  # pylint: disable=broad-except
        logger.error("shelf_status: error querying SQL: %s", exc, exc_info=True)
        return func.HttpResponse(
            json.dumps({"error": str(exc)}),
            mimetype="application/json",
            status_code=500,
        )


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


def _query_shelf_status(store_id: str | None, shelf_id: str | None) -> dict:
    conn_str = _build_connection_string()

    with pyodbc.connect(conn_str, timeout=30) as conn:
        cursor = conn.cursor()

        # Latest readings
        query = """
            SELECT TOP 100
                sr.ReadingId,
                sr.BlobName,
                sr.CapturedAt,
                sr.AvailabilityScore,
                sr.FilledSlots,
                sr.EmptySlots,
                sh.ShelfCode,
                sh.Aisle,
                st.StoreCode,
                st.StoreName
            FROM dbo.ShelfReadings sr
            INNER JOIN dbo.Shelves sh ON sh.ShelfId = sr.ShelfId
            INNER JOIN dbo.Stores  st ON st.StoreId = sr.StoreId
            WHERE 1=1
        """
        params: list = []

        if store_id:
            query += " AND st.StoreCode = ?"
            params.append(store_id)
        if shelf_id:
            query += " AND sh.ShelfCode = ?"
            params.append(shelf_id)

        query += " ORDER BY sr.CapturedAt DESC"
        cursor.execute(query, params)
        columns = [col[0] for col in cursor.description]
        readings = [dict(zip(columns, row)) for row in cursor.fetchall()]

        # Active alerts
        alert_query = """
            SELECT TOP 50
                a.AlertId,
                a.Severity,
                a.AvailabilityScore,
                a.Message,
                a.CreatedAt,
                sh.ShelfCode,
                st.StoreCode
            FROM dbo.Alerts a
            INNER JOIN dbo.Shelves sh ON sh.ShelfId = a.ShelfId
            INNER JOIN dbo.Stores  st ON st.StoreId = a.StoreId
            WHERE a.IsProcessed = 0
        """
        alert_params: list = []

        if store_id:
            alert_query += " AND st.StoreCode = ?"
            alert_params.append(store_id)
        if shelf_id:
            alert_query += " AND sh.ShelfCode = ?"
            alert_params.append(shelf_id)

        alert_query += " ORDER BY a.CreatedAt DESC"
        cursor.execute(alert_query, alert_params)
        alert_columns = [col[0] for col in cursor.description]
        alerts = [dict(zip(alert_columns, row)) for row in cursor.fetchall()]

    return {
        "readings": readings,
        "active_alerts": alerts,
        "total_readings": len(readings),
        "total_active_alerts": len(alerts),
    }
