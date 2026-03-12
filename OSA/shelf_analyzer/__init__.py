"""
shelf_analyzer – Event Hub Triggered Function
Processes shelf alert events from 'event-hub-osa'.
Logs analytics data and can be extended for downstream processing.
"""

import json
import logging
from typing import List

import azure.functions as func

logger = logging.getLogger(__name__)


def main(events: List[func.EventHubEvent]) -> None:
    """Process a batch of Event Hub events.

    Args:
        events: List of EventHub events (cardinality: many).
    """
    for event in events:
        try:
            body = event.get_body().decode("utf-8")
            payload = json.loads(body)

            store_id          = payload.get("store_id", "unknown")
            shelf_id          = payload.get("shelf_id", "unknown")
            severity          = payload.get("severity", "unknown")
            availability_score = payload.get("availability_score", None)

            logger.info(
                "shelf_analyzer: received event. store_id=%s shelf_id=%s "
                "severity=%s availability_score=%s",
                store_id,
                shelf_id,
                severity,
                availability_score,
            )

            # Extension point: add downstream analytics processing here
            # e.g., aggregate metrics, trigger reorder workflows, etc.

        except json.JSONDecodeError as exc:
            logger.error("Failed to decode event body: %s", exc)
        except Exception as exc:  # pylint: disable=broad-except
            logger.error("Unexpected error processing event: %s", exc, exc_info=True)
