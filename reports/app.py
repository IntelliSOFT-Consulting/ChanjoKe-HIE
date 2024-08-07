import atexit
from datetime import datetime, timedelta

from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.interval import IntervalTrigger
from flask import jsonify, request
from flask_cors import CORS

import hive
import pg
from configs import app, db
from reports.moh_710_report import moh_710_report

CORS(app)


scheduler = BackgroundScheduler()
scheduler.start()
scheduler.add_job(
    func=hive.query_data,
    trigger=IntervalTrigger(minutes=30),
    id="query_data_job",
    name="Query data from Hive every 30 minutes",
    replace_existing=True,
)

atexit.register(lambda: scheduler.shutdown())


@app.route("/api/analytics", methods=["POST"])
def analytics():
    try:
        hive.query_data()
        return jsonify({"message": "Data fetched and inserted into the database"})
    except Exception as e:
        return jsonify({"message": str(e)}), 500


@app.route("/api/defaulters", methods=["GET"])
def defaulters():
    try:
        name = request.args.get("name", "")
        vaccine_name = request.args.get("vaccine_name", "")
        start_date = request.args.get("start_date", "")
        end_date = request.args.get("end_date", "")
        page = request.args.get("page", 1)
        per_page = request.args.get("per_page", 20)
        result = pg.query_defaulters(name, vaccine_name, start_date, end_date, page, per_page)
        return jsonify(result)
    except Exception as e:
        return jsonify({"message": str(e)}), 500


@app.route("/api/moh_710_report", methods=["GET"])
def moh_710_report_endpoint():

    
    filters = {
        "facility": request.args.get("facility", ""),
        "facility_code": request.args.get("facility_code", ""),
        "ward": request.args.get("ward", ""),
        "county": request.args.get("county", ""),
        "subcounty": request.args.get("subcounty", ""),
        # The dates are YYYY-MM-DD strings, hence the strftime
        "start_date": request.args.get("start_date", (datetime.now() - timedelta(days=365)).strftime("%Y-%m-%d")),
        "end_date": request.args.get("end_date", (datetime.now()).strftime("%Y-%m-%d")),
    }
    try:
        result = moh_710_report(filters)
        return result
    except Exception as e:
        return jsonify({"message": str(e)}), 500


if __name__ == "__main__":
    app.run(debug=True)
    db.create_all()
    app.run(debug=True)
