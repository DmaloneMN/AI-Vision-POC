"""
shelf_detector_blob – Alternative Blob Trigger Function
Legacy/alternative blob trigger that starts the shelf_orchestrator durable orchestration.
Mirrors blob_trigger_starter but registered under a different function name for
compatibility with the ARM template deployment.
"""

import logging
from datetime import datetime, timezone
import os

import azure.functions as func
import azure.durable_functions as df

logger = logging.getLogger(__name__)


async def main(myblob: func.InputStream, starter: str) -> None:
    """Entry point for the alternative blob trigger function.

    Args:
        myblob: The incoming blob that triggered the function.
        starter: Durable Functions client binding string.
    """
    client = df.DurableOrchestrationClient(starter)

    blob_name: str = myblob.name
    blob_uri: str  = _build_blob_uri(blob_name)
    store_id, shelf_id, timestamp = _parse_blob_metadata(blob_name)

    input_payload = {
        "blob_name": blob_name,
        "blob_url": blob_uri,
        "store_id": store_id,
        "shelf_id": shelf_id,
        "timestamp": timestamp,
    }

    logger.info(
        "shelf_detector_blob triggered. blob_name=%s store_id=%s shelf_id=%s",
        blob_name,
        store_id,
        shelf_id,
    )

    instance_id = await client.start_new("shelf_orchestrator", None, input_payload)
    logger.info("Started orchestration with ID='%s'.", instance_id)


def _parse_blob_metadata(blob_name: str) -> tuple:
    parts = blob_name.replace("shelf-images/", "").split("/")
    store_id = parts[0] if len(parts) > 0 else "unknown-store"
    shelf_id = parts[1] if len(parts) > 1 else "unknown-shelf"
    timestamp = datetime.now(timezone.utc).isoformat()

    if len(parts) > 2:
        filename = parts[2]
        ts_part = filename.split("_")[0]
        try:
            parsed = datetime.strptime(ts_part, "%Y%m%dT%H%M%S")
            timestamp = parsed.replace(tzinfo=timezone.utc).isoformat()
        except ValueError:
            pass

    return store_id, shelf_id, timestamp


def _build_blob_uri(blob_name: str) -> str:
    account_name = os.environ.get("STORAGE_ACCOUNT_NAME", "")
    if account_name:
        return f"https://{account_name}.blob.core.windows.net/{blob_name}"
    return blob_name
