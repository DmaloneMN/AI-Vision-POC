"""
shelf_orchestrator – Durable Orchestrator Function
Chains the following activities for each shelf image:
  1. AnalyzeImageActivity  – calls Custom Vision / AI Vision
  2. WritePredictionActivity – persists predictions to SQL
  3. PersistAlertActivity    – evaluates thresholds, creates alerts
  4. PublishEventActivity    – publishes alert event to Event Hub (conditional)
"""

import logging

import azure.durable_functions as df

logger = logging.getLogger(__name__)


def orchestrator_function(context: df.DurableOrchestrationContext):
    """Orchestrator that coordinates shelf image analysis activities.

    Args:
        context: The durable orchestration context.

    Yields:
        Task results from activity calls.
    """
    input_data: dict = context.get_input()

    blob_name: str = input_data.get("blob_name", "")
    blob_url: str = input_data.get("blob_url", "")
    store_id: str = input_data.get("store_id", "unknown")
    shelf_id: str = input_data.get("shelf_id", "unknown")
    timestamp: str = input_data.get("timestamp", "")

    if not context.is_replaying:
        logger.info(
            "Orchestration started. instance_id=%s blob_name=%s",
            context.instance_id,
            blob_name,
        )

    # Step 1: Analyze the image
    analyze_input = {
        "blob_url": blob_url,
        "blob_name": blob_name,
        "store_id": store_id,
        "shelf_id": shelf_id,
    }
    analysis_result: dict = yield context.call_activity("AnalyzeImageActivity", analyze_input)

    # Step 2: Write prediction to SQL
    write_input = {
        "analysis": analysis_result,
        "store_id": store_id,
        "shelf_id": shelf_id,
        "blob_name": blob_name,
        "blob_url": blob_url,
        "timestamp": timestamp,
    }
    prediction_result: dict = yield context.call_activity("WritePredictionActivity", write_input)

    # Step 3: Evaluate thresholds and persist alert
    alert_input = {
        "availability_score": analysis_result.get("availability_score", 100.0),
        "store_id": store_id,
        "shelf_id": shelf_id,
        "reading_id": prediction_result.get("reading_id"),
    }
    alert_result: dict = yield context.call_activity("PersistAlertActivity", alert_input)

    # Step 4: Publish event only if an alert was created
    if alert_result.get("alert_created"):
        publish_input = {
            "alert": alert_result,
            "store_id": store_id,
            "shelf_id": shelf_id,
            "blob_name": blob_name,
            "timestamp": timestamp,
        }
        yield context.call_activity("PublishEventActivity", publish_input)

    if not context.is_replaying:
        logger.info(
            "Orchestration complete. instance_id=%s availability_score=%.2f alert_created=%s",
            context.instance_id,
            analysis_result.get("availability_score", 0),
            alert_result.get("alert_created", False),
        )

    return {
        "instance_id": context.instance_id,
        "blob_name": blob_name,
        "analysis": analysis_result,
        "alert": alert_result,
    }


main = df.Orchestrator.create(orchestrator_function)
