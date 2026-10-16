from fastapi import APIRouter, Request

from .auth import CurrentUser
from .schemas import Plantilla

router = APIRouter(tags=["catálogo"])


@router.get("/plantillas", response_model=list[Plantilla])
def list_templates(request: Request, user: CurrentUser):
    with request.app.state.db.connect() as conn:
        return [dict(row) for row in conn.execute("SELECT * FROM plantillas ORDER BY id")]
