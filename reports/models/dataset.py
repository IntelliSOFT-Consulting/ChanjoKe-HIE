from configs import db
from sqlalchemy.orm import Mapped


class PrimaryImmunizationDataset(db.Model):
    __tablename__ = "primary_immunization_dataset"
    id: Mapped[int] = db.Column(db.Integer, primary_key=True)
    patient_id: Mapped[str] = db.Column(db.String, nullable=True)
    family_name: Mapped[str] = db.Column(db.String, nullable=True)
    given_name: Mapped[str] = db.Column(db.String, nullable=True)
    national_id: Mapped[str] = db.Column(db.String, nullable=True)
    patient_update_date: Mapped[str] = db.Column(db.String, nullable=True)
    phone: Mapped[str] = db.Column(db.String, nullable=True)
    gender: Mapped[str] = db.Column(db.String, nullable=True)
    birth_date: Mapped[str] = db.Column(db.String, nullable=True)
    the_age: Mapped[str] = db.Column(db.String, nullable=True)
    age_y: Mapped[int] = db.Column(db.Integer, nullable=True)
    age_m: Mapped[int] = db.Column(db.Integer, nullable=True)
    age_group: Mapped[str] = db.Column(db.String, nullable=True)
    active: Mapped[bool] = db.Column(db.Boolean, nullable=True)
    deceased: Mapped[bool] = db.Column(db.Boolean, nullable=True)
    marital_status: Mapped[str] = db.Column(db.String, nullable=True)
    multiple_birth: Mapped[bool] = db.Column(db.Boolean, nullable=True)
    pat_relation: Mapped[str] = db.Column(db.String, nullable=True)
    pat_relation_name: Mapped[str] = db.Column(db.String, nullable=True)
    pat_relation_tel: Mapped[str] = db.Column(db.String, nullable=True)
    due_date: Mapped[str] = db.Column(db.String, nullable=True)
    county: Mapped[str] = db.Column(db.String, nullable=True)
    subcounty: Mapped[str] = db.Column(db.String, nullable=True)
    ward: Mapped[str] = db.Column(db.String, nullable=True)
    facility: Mapped[str] = db.Column(db.String, nullable=True)
    facility_code: Mapped[str] = db.Column(db.String, nullable=True)
    the_vaccine_seq: Mapped[int] = db.Column(db.Integer, nullable=True)
    vaccine_code: Mapped[str] = db.Column(db.String, nullable=True)
    vaccine_name: Mapped[str] = db.Column(db.String, nullable=True)
    vaccine_category: Mapped[str] = db.Column(db.String, nullable=True)
    the_dose: Mapped[int] = db.Column(db.Integer, nullable=True)
    description: Mapped[str] = db.Column(db.String, nullable=True)
    series: Mapped[str] = db.Column(db.String, nullable=True)
    occ_date: Mapped[str] = db.Column(db.String, nullable=True)
    days_from_due: Mapped[int] = db.Column(db.Integer, nullable=True)
    faci_outr: Mapped[str] = db.Column(db.String, nullable=True)
    imm_status: Mapped[str] = db.Column(db.String, nullable=True)
    imm_status_defaulter: Mapped[str] = db.Column(db.String, nullable=True)
