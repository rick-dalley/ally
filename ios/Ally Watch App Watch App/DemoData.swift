import Foundation

// Sample data for the "View Demo" links — lets a screen be checked (and
// screenshotted) with zero pairing/network involved, since real pairing is a
// separate, unrelated prerequisite (Bluetooth pairing the watch and phone, then
// opening Ally on the phone).
enum DemoData {
    static let dueItems: [String: Any] = [
        "medications": [
            ["id": "demo-med-1", "name": "Lisinopril", "dose": "10 mg", "freq": "qd"],
            ["id": "demo-med-2", "name": "Metformin", "dose": "500 mg", "freq": "bid"],
            ["id": "demo-med-3", "name": "Atorvastatin", "dose": "20 mg", "freq": "qd"],
        ],
        "careOrders": [
            ["id": "demo-order-1", "label": "Physical Therapy", "directions": "Walk 10 minutes, twice daily"]
        ],
        "doneMedicationIds": [String](),
        "doneCareOrderIds": [String](),
    ]

    static let alerts: [String: Any] = [
        "manual": true,
        "fall": true,
        "slap": false,
    ]

    static let emergencyQr: [String: Any] = [
        "name": "Demo Patient",
        "phn": "9876 543 210",
        "bloodType": "O+",
        "allergies": ["Penicillin"],
        "conditions": ["Type 2 Diabetes"],
        "familyDoctor": ["name": "Dr. Demo", "phone": "555-0100"],
        "emergencyContact": ["name": "Demo Contact", "phone": "555-0199"],
    ]
}
