"""
AnalyzeImageActivity – Durable Activity Function
Calls Custom Vision prediction endpoint for a given shelf image URL.
Computes an On-Shelf Availability (OSA) score from the predictions.

Returns a dict with:
  - predictions: list of {tag, probability}
  - availability_score: float 0-100
  - filled_slots: int
  - empty_slots: int
"""

import logging
import os

logger = logging.getLogger(__name__)

# Availability thresholds tag names (Custom Vision model specific)
FILLED_TAGS = {"filled", "product", "in-stock"}
EMPTY_TAGS  = {"empty", "gap", "out-of-stock", "oos"}


def main(payload: dict) -> dict:
    """Activity entry point.

    Args:
        payload: Dict containing blob_url, blob_name, store_id, shelf_id.

    Returns:
        Dict with predictions list, availability_score, filled_slots, empty_slots.
    """
    blob_url: str = payload.get("blob_url", "")
    blob_name: str = payload.get("blob_name", "")

    logger.info("AnalyzeImageActivity: analyzing blob_name=%s", blob_name)

    predictions = _call_custom_vision(blob_url)
    availability_score, filled_slots, empty_slots = _compute_osa_score(predictions)

    logger.info(
        "AnalyzeImageActivity: blob_name=%s availability_score=%.2f filled=%d empty=%d",
        blob_name,
        availability_score,
        filled_slots,
        empty_slots,
    )

    return {
        "predictions": predictions,
        "availability_score": availability_score,
        "filled_slots": filled_slots,
        "empty_slots": empty_slots,
        "blob_name": blob_name,
        "blob_url": blob_url,
    }


def _call_custom_vision(image_url: str) -> list:
    """Call the Custom Vision prediction endpoint.

    Falls back to a mock response if environment variables are not configured.
    """
    endpoint = os.environ.get("CUSTOM_VISION_ENDPOINT", "")
    key = os.environ.get("CUSTOM_VISION_KEY", "")
    project_id = os.environ.get("CUSTOM_VISION_PROJECT_ID", "")
    iteration = os.environ.get("CUSTOM_VISION_ITERATION", "")

    if not all([endpoint, key, project_id, iteration]):
        logger.warning("Custom Vision env vars not fully configured – returning mock predictions.")
        return _mock_predictions()

    try:
        from msrest.authentication import ApiKeyCredentials
        from azure.cognitiveservices.vision.customvision.prediction import CustomVisionPredictionClient

        credentials = ApiKeyCredentials(in_headers={"Prediction-key": key})
        predictor = CustomVisionPredictionClient(endpoint=endpoint, credentials=credentials)

        result = predictor.detect_image_url(project_id, iteration, url=image_url)

        return [
            {
                "tag": p.tag_name,
                "probability": round(p.probability, 4),
                "bounding_box": {
                    "left":   p.bounding_box.left   if p.bounding_box else None,
                    "top":    p.bounding_box.top    if p.bounding_box else None,
                    "width":  p.bounding_box.width  if p.bounding_box else None,
                    "height": p.bounding_box.height if p.bounding_box else None,
                },
            }
            for p in result.predictions
            if p.probability >= 0.5
        ]
    except Exception as exc:  # pylint: disable=broad-except
        logger.error("Custom Vision call failed: %s", exc, exc_info=True)
        raise


def _compute_osa_score(predictions: list) -> tuple:
    """Compute availability score from predictions.

    Returns:
        Tuple of (availability_score, filled_slots, empty_slots).
    """
    filled_slots = sum(
        1 for p in predictions if p.get("tag", "").lower() in FILLED_TAGS
    )
    empty_slots = sum(
        1 for p in predictions if p.get("tag", "").lower() in EMPTY_TAGS
    )
    total_slots = filled_slots + empty_slots

    if total_slots == 0:
        return 100.0, 0, 0

    availability_score = round((filled_slots / total_slots) * 100, 2)
    return availability_score, filled_slots, empty_slots


def _mock_predictions() -> list:
    """Return a mock prediction list for local testing."""
    return [
        {"tag": "filled", "probability": 0.95, "bounding_box": None},
        {"tag": "filled", "probability": 0.92, "bounding_box": None},
        {"tag": "empty",  "probability": 0.88, "bounding_box": None},
        {"tag": "filled", "probability": 0.85, "bounding_box": None},
    ]
