from contextlib import asynccontextmanager
from typing import AsyncGenerator, List
import logging
import mangum

from fastapi import FastAPI, HTTPException, Depends, Request,Session

from sqlalchemy.orm import Session

import models, schemas, crud
from database import Base, build_engine, build_session_factory

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator:
    """
    Startup: Runs during Lambda 'Init' or first request.
    Shutdown: Runs when the Lambda container is destroyed.
    """
    # 1. Initialize DB Resources
    engine = build_engine()
    session_factory = build_session_factory(engine)
    
    # 2. Schema Management (Optional: remove if using Alembic)
    # Base.metadata.create_all(bind=engine) 

    # 3. Store in app.state (This is 'saved' in Lambda memory)
    app.state.engine = engine
    app.state.session_factory = session_factory

    logger.info("Lambda cold start: Database engine and factory initialized.")

    yield  # App handles requests here

    # 4. Cleanup
    engine.dispose()
    logger.info("Lambda container shutting down: Database engine disposed.")


app = FastAPI(title="FastAPI CRUD App", version="1.0.0", lifespan=lifespan)

# --- Dependency ---

def get_db(request: Request) -> Session:
    """Dependency that provides a session from the app state."""
    session_factory = request.app.state.session_factory
    db = session_factory()
    try:
        yield db
    finally:
        db.close()

# --- Routes ---

@app.get("/")
def root():
    return {"message": "FastAPI on Lambda is running!", "status": "healthy"}

@app.post("/items/", response_model=schemas.Item, status_code=201)
def create_item(item: schemas.ItemCreate, db: Session = Depends(get_db)):
    return crud.create_item(db=db, item=item)

@app.get("/items/", response_model=List[schemas.Item])
def read_items(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return crud.get_items(db, skip=skip, limit=limit)

@app.get("/items/{item_id}", response_model=schemas.Item)
def read_item(item_id: int, db: Session = Depends(get_db)):
    db_item = crud.get_item(db, item_id=item_id)
    if not db_item:
        raise HTTPException(status_code=404, detail="Item not found")
    return db_item

@app.put("/items/{item_id}", response_model=schemas.Item, status_code=200)
def update_item(item_id: int, item: schemas.ItemUpdate, db: Session = Depends(get_db)):
    db_item = crud.update_item(db, item_id=item_id, item_update=item)
    if db_item is None:
        raise HTTPException(status_code=404, detail="Item not found")
    return db_item

@app.delete("/items/{item_id}")
def delete_item(item_id: int, db: Session = Depends(get_db)):
    if not crud.delete_item(db, item_id=item_id):
        raise HTTPException(status_code=404, detail="Item not found")
    return {"message": "Item deleted successfully"}

# Mangum handler for AWS Lambda
handler = mangum.Mangum(app, lifespan="auto")
