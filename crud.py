from sqlalchemy.orm import Session
import models, schemas


def create_item(db: Session, item: schemas.ItemCreate) -> models.Item:
    db_item = models.Item(**item.model_dump())
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item


def get_items(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.Item).offset(skip).limit(limit).all()


def get_item(db: Session, item_id: int):
    return db.query(models.Item).filter(models.Item.id == item_id).first()


def update_item(db: Session, item_id: int, item_update: schemas.ItemUpdate):
    db_item = db.query(models.Item).filter(models.Item.id == item_id).first()
    if not db_item:
        return None
    
    # .model_dump(exclude_unset=True) is the "magic" for partial updates
    update_data = item_update.model_dump(exclude_unset=True)
    
    for key, value in update_data.items():
        setattr(db_item, key, value)
    
    db.commit()
    db.refresh(db_item)
    return db_item


def delete_item(db: Session, item_id: int) -> bool:
    db_item = get_item(db, item_id)
    if not db_item:
        return False
    db.delete(db_item)
    db.commit()
    return True
