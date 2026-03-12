"""
PublishEventActivity – Durable Activity Function
Publishes an alert event to Azure Event Hub using the azure-eventhub SDK.
"""

import json
import logging
import os
from datetime import datetime, timezone

from azure.eventhub import EventHubProducerClient, EventData

logger = logging.getLogger(__name__)


def main(payload: dict) -> dict:
    """Activity entry point.

    Args:
        payload: Dict with alert details, store_id, shelf_id, blob_name, timestamp.

    Returns:
        Dict confirming the event was published.
    """
    alert: dict    = payload.get("alert", {})
    store_id: str  = payload.get("store_id", "unknown")
    shelf_id: str  = payload.get("shelf_id", "unknown")
    blob_name: str = payload.get("blob_name", "")
    timestamp: str = payload.get("timestamp", datetime.now(timezone.utc).isoformat())

    event_body = {
        "event_type": "ShelfAlert",
        "store_id": store_id,
        "shelf_id": shelf_id,
        "blob_name": blob_name,
        "timestamp": timestamp,
        "alert_id": alert.get("alert_id"),
        "severity": alert.get("severity"),
        "availability_score": alert.get("availability_score"),
        "message": (
            f"Shelf {shelf_id} in store {store_id} has availability score "
            f"{alert.get('availability_score', 0):.1f}% – {alert.get('severity', 'Unknown')}"
        ),
    }

    conn_str = os.environ.get("EVENT_HUB_CONN", "")
    eventhub_name = "event-hub-osa"

    logger.info(
        "PublishEventActivity: publishing alert event. store_id=%s severity=%s",
        store_id,
        alert.get("severity"),
    )

    if not conn_str:
        logger.warning("EVENT_HUB_CONN not configured – skipping Event Hub publish.")
        return {"published": False, "reason": "EVENT_HUB_CONN not set"}

    producer = EventHubProducerClient.from_connection_string(
        conn_str=conn_str, eventhub_name=eventhub_name
    )
    with producer:
        event_data_batch = producer.create_batch()
        event_data_batch.add(EventData(json.dumps(event_body)))
        producer.send_batch(event_data_batch)

    logger.info("PublishEventActivity: event published successfully.")
    return {"published": True}
