from typing import Dict, Set
from fastapi import HTTPException, status


ORDER_STATES = {
    "PENDING",
    "PAID",
    "SHIPPED",
    "DELIVERED",
    "CANCELLED",
}

ALLOWED_TRANSITIONS: Dict[str, Set[str]] = {
    "PENDING": {"PAID", "CANCELLED"},
    "PAID": {"SHIPPED"},
    "SHIPPED": {"DELIVERED"},
    "DELIVERED": set(),
    "CANCELLED": set(),
}


def validate_status(status_value: str) -> None:

    if status_value not in ORDER_STATES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid order status '{status_value}'",
        )


def validate_transition(current_status: str, target_status: str) -> None:

    validate_status(current_status)
    validate_status(target_status)

    allowed_targets = ALLOWED_TRANSITIONS[current_status]

    if target_status not in allowed_targets:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=(
                f"Invalid order status transition: "
                f"{current_status} → {target_status}"
            ),
        )