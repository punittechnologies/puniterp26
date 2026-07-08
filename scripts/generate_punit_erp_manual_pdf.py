from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import (
    Image,
    KeepTogether,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "output/pdf/punit-erp-feature-manual-technical-specs.pdf"
LOGO = ROOT / "apps/platform/public/brand/punit-logo.png"


PRIMARY = colors.HexColor("#0B57D0")
INK = colors.HexColor("#0F1B2D")
MUTED = colors.HexColor("#526176")
SOFT = colors.HexColor("#EEF5FF")
LINE = colors.HexColor("#D8E4F3")
GREEN = colors.HexColor("#087A4A")


def styles():
    base = getSampleStyleSheet()
    return {
        "title": ParagraphStyle(
            "Title",
            parent=base["Title"],
            fontName="Helvetica-Bold",
            fontSize=26,
            leading=31,
            textColor=INK,
            alignment=TA_CENTER,
            spaceAfter=8,
        ),
        "subtitle": ParagraphStyle(
            "Subtitle",
            parent=base["BodyText"],
            fontName="Helvetica",
            fontSize=11,
            leading=16,
            textColor=MUTED,
            alignment=TA_CENTER,
            spaceAfter=18,
        ),
        "h1": ParagraphStyle(
            "H1",
            parent=base["Heading1"],
            fontName="Helvetica-Bold",
            fontSize=18,
            leading=23,
            textColor=PRIMARY,
            spaceBefore=8,
            spaceAfter=8,
        ),
        "h2": ParagraphStyle(
            "H2",
            parent=base["Heading2"],
            fontName="Helvetica-Bold",
            fontSize=13,
            leading=17,
            textColor=INK,
            spaceBefore=6,
            spaceAfter=4,
        ),
        "body": ParagraphStyle(
            "Body",
            parent=base["BodyText"],
            fontName="Helvetica",
            fontSize=9.3,
            leading=13.5,
            textColor=INK,
            spaceAfter=5,
        ),
        "small": ParagraphStyle(
            "Small",
            parent=base["BodyText"],
            fontName="Helvetica",
            fontSize=8,
            leading=11,
            textColor=MUTED,
        ),
        "cardTitle": ParagraphStyle(
            "CardTitle",
            parent=base["BodyText"],
            fontName="Helvetica-Bold",
            fontSize=10.5,
            leading=13,
            textColor=PRIMARY,
            spaceAfter=3,
        ),
        "cardBody": ParagraphStyle(
            "CardBody",
            parent=base["BodyText"],
            fontName="Helvetica",
            fontSize=8.3,
            leading=11.5,
            textColor=INK,
        ),
        "center": ParagraphStyle(
            "Center",
            parent=base["BodyText"],
            fontName="Helvetica-Bold",
            fontSize=9,
            leading=12,
            textColor=INK,
            alignment=TA_CENTER,
        ),
    }


S = styles()


def p(text, style="body"):
    return Paragraph(text, S[style])


def bullets(items):
    return [p(f"- {item}") for item in items]


def card_grid(items, columns=2):
    rows = []
    for i in range(0, len(items), columns):
        row = []
        for title, body in items[i : i + columns]:
            row.append([p(title, "cardTitle"), p(body, "cardBody")])
        while len(row) < columns:
            row.append("")
        rows.append(row)
    table = Table(rows, colWidths=[82 * mm] * columns, hAlign="LEFT")
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, -1), colors.white),
                ("BOX", (0, 0), (-1, -1), 0.6, LINE),
                ("INNERGRID", (0, 0), (-1, -1), 0.6, LINE),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 8),
                ("RIGHTPADDING", (0, 0), (-1, -1), 8),
                ("TOPPADDING", (0, 0), (-1, -1), 7),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
            ]
        )
    )
    return table


def simple_table(headers, rows, widths=None):
    data = [[p(h, "center") for h in headers]]
    for row in rows:
        data.append([p(str(cell), "small") for cell in row])
    table = Table(data, colWidths=widths, repeatRows=1)
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), PRIMARY),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("GRID", (0, 0), (-1, -1), 0.4, LINE),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 5),
                ("RIGHTPADDING", (0, 0), (-1, -1), 5),
                ("TOPPADDING", (0, 0), (-1, -1), 5),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
            ]
        )
    )
    return table


def header_footer(canvas, doc):
    canvas.saveState()
    width, height = A4
    canvas.setStrokeColor(LINE)
    canvas.line(18 * mm, height - 16 * mm, width - 18 * mm, height - 16 * mm)
    canvas.setFillColor(PRIMARY)
    canvas.setFont("Helvetica-Bold", 9)
    canvas.drawString(18 * mm, height - 12 * mm, "Punit ERP")
    canvas.setFillColor(MUTED)
    canvas.setFont("Helvetica", 8)
    canvas.drawRightString(width - 18 * mm, height - 12 * mm, "Weighing Automation and Software")
    canvas.setStrokeColor(LINE)
    canvas.line(18 * mm, 15 * mm, width - 18 * mm, 15 * mm)
    canvas.setFillColor(MUTED)
    canvas.setFont("Helvetica", 7.5)
    canvas.drawString(
        18 * mm,
        10 * mm,
        "Built inhouse by engineers of Punit Instrument Pvt Ltd and Punit Technologies | Support: +91 9737599004",
    )
    canvas.drawRightString(width - 18 * mm, 10 * mm, f"Page {doc.page}")
    canvas.restoreState()


def build():
    OUT.parent.mkdir(parents=True, exist_ok=True)
    doc = SimpleDocTemplate(
        str(OUT),
        pagesize=A4,
        rightMargin=18 * mm,
        leftMargin=18 * mm,
        topMargin=23 * mm,
        bottomMargin=20 * mm,
    )
    story = []
    if LOGO.exists():
        logo = Image(str(LOGO), width=42 * mm, height=42 * mm)
        logo.hAlign = "CENTER"
        story += [logo, Spacer(1, 6)]
    story += [
        p("Punit ERP", "title"),
        p(
            "Weighing, label printing, inventory, inward reporting and dispatch management system",
            "subtitle",
        ),
        card_grid(
            [
                ("Purpose", "A factory-grade platform for weighing material, printing barcode labels, tracking stock and dispatching scanned goods."),
                ("Designed For", "Industrial tablets, Android mobile devices, web administrators, scale operators and dispatch teams."),
                ("Connectivity", "Cloud-first Laravel web panel with Android app sync, Bluetooth weighing scale support and TVS label printer flow."),
                ("Business Result", "Accurate weights, searchable barcodes, instant reports, reduced manual entry and better stock visibility."),
            ]
        ),
        Spacer(1, 10),
        p("1. Feature List", "h1"),
        card_grid(
            [
                ("Web Admin Panel", "Products, product details, app users, customers, inventory, inward reports, dispatch reports, report customisation and audit-ready operations."),
                ("Android Weighing App", "Live scale weight, product selection, tare, net weight, label printing, recent entries, inward sessions and cloud sync."),
                ("Bluetooth Scale", "Real Bluetooth scale connection with raw data parsing, stable reading detection and diagnostics."),
                ("Label Printing", "TVS-compatible label printing from saved app templates with product fields, weights, barcode and optional logo/layout settings."),
                ("Inward Report", "Start transaction, weigh and print multiple labels, stop transaction, then generate inward report PDF/Excel records."),
                ("Dispatch Report", "Select customer, scan barcode by camera/Bluetooth scanner, validate stock and generate dispatch/packing list."),
                ("Inventory", "Product-wise and product-detail-wise stock using production additions and dispatch deductions."),
                ("Cloud Sync", "Internet-first sync for production, inward sessions, dispatch and reports, with local emergency queue when offline."),
            ]
        ),
        Spacer(1, 8),
        p("2. Operator Manual - Weighing and Inward", "h1"),
        *bullets(
            [
                "Open the Punit ERP app and login with the app user ID/password created from the web panel.",
                "Confirm the scale and printer icons show connected on the top bar.",
                "Select the product and fill product detail fields such as size, color, GSM, MTR or quality as configured by admin.",
                "Tap Start Transaction before beginning a batch/inward session.",
                "Place material on the scale. Check gross, tare and net weight. Tare can be edited manually if required.",
                "Tap Save & Print Label. The app saves the entry, prints the label and pushes the record to the web server.",
                "Recent Weighments shows only the current open transaction entries. Use delete with password if a mistaken entry is made before finalising.",
                "Tap Stop Transaction to close the inward session and generate/report the transaction on the web panel.",
            ]
        ),
        p("3. Operator Manual - Dispatch", "h1"),
        *bullets(
            [
                "Open Dispatch in the app.",
                "Select the customer.",
                "Scan labels using the mobile camera or a Bluetooth barcode scanner in keyboard mode.",
                "Each barcode is checked against the live web server first. If internet is unavailable, local fallback is used where possible.",
                "Duplicate, already dispatched or unknown barcodes are rejected.",
                "Tap Save Dispatch to confirm. Inventory is deducted and the dispatch/packing report becomes visible in web reports.",
            ]
        ),
        PageBreak(),
        p("4. Web Admin Manual", "h1"),
        simple_table(
            ["Module", "Use"],
            [
                ["Products", "Create simple products with optional tare, weight range and conversion settings."],
                ["Product Details", "Create dropdown product detail fields and values that are used in app, labels and reports."],
                ["App Users", "Create separate app login IDs/passwords and assign roles/permissions for operators."],
                ["Report Customiser", "Configure company details, logo, report columns, PDF/Excel fields and email report preferences."],
                ["Inward Report", "View transaction cards, filter by product/detail/barcode/date and download PDF/Excel."],
                ["Dispatch Report", "View dispatch/packing list cards, filter records and download customer-wise reports."],
                ["Inventory", "View bird's-eye product and product-detail stock balances."],
                ["Customers", "Maintain customer list used by dispatch."],
            ],
            widths=[45 * mm, 125 * mm],
        ),
        Spacer(1, 10),
        p("5. Benefits", "h1"),
        card_grid(
            [
                ("Less Manual Entry", "Weight comes directly from scale and barcode is generated automatically."),
                ("Traceability", "Each label links to product, product details, weight, operator, device and transaction."),
                ("Fast Dispatch", "Scan labels, validate stock and generate dispatch report quickly."),
                ("Stock Control", "Inventory increases on inward production and decreases on dispatch."),
                ("Audit Friendly", "Reports and transaction records are available from the web panel."),
                ("Offline Emergency", "App can keep working locally during internet failure and sync when connectivity returns."),
            ]
        ),
        Spacer(1, 8),
        p("6. Technical Working", "h1"),
        simple_table(
            ["Area", "Technical Design"],
            [
                ["Backend", "Laravel API and web panel with tenant isolation, permissions, Sanctum authentication and MySQL storage."],
                ["Mobile App", "Flutter Android app with local Drift/SQLite storage, Riverpod/navigation structure and responsive tablet/mobile UI."],
                ["Scale", "Bluetooth scale adapter reads continuous serial data, parses configured weight packets and detects stable readings."],
                ["Printer", "Bluetooth thermal/TVS label path sends TSPL-style label commands with barcode, product data and weight fields."],
                ["Sync", "Production, inward and dispatch are queued locally, pushed immediately to web with idempotency keys and retried on failure."],
                ["Reports", "Web report screens generate transaction lists, PDF/Excel/CSV exports and customer/stock summaries."],
                ["Security", "Separate app-user login, token-based API access, permission checks and tenant-scoped records."],
                ["Storage", "Operational records sync to server; local data can be purged after successful sync to reduce device storage load."],
            ],
            widths=[38 * mm, 132 * mm],
        ),
        Spacer(1, 10),
        p("7. Recommended Daily Flow", "h1"),
        *bullets(
            [
                "Morning: open app, login if required, verify scale/printer connection and sync status.",
                "Production: start inward transaction, weigh items, print labels and stop transaction after batch completion.",
                "Dispatch: select customer, scan labels, confirm dispatch and verify dispatch report.",
                "Admin: check dashboard, inward reports, dispatch reports, inventory and failed sync status.",
            ]
        ),
        p("8. Support", "h1"),
        p(
            "For software training and support contact Punit Instrument Pvt Ltd at +91 9737599004. Website: punitinstrument.com.",
            "body",
        ),
    ]
    doc.build(story, onFirstPage=header_footer, onLaterPages=header_footer)
    print(OUT)


if __name__ == "__main__":
    build()
