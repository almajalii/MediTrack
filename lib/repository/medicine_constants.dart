// Dosage frequency presets
class FrequencyOption {
  final String label;
  final List<String> defaultTimes;
  final bool requiresTimes;

  const FrequencyOption({
    required this.label,
    required this.defaultTimes,
    this.requiresTimes = true,
  });
}

const List<FrequencyOption> dosageFrequencies = [
  FrequencyOption(label: 'Once Daily',         defaultTimes: ['8:00 AM']),
  FrequencyOption(label: 'Twice Daily',         defaultTimes: ['8:00 AM', '8:00 PM']),
  FrequencyOption(label: 'Three Times Daily',   defaultTimes: ['8:00 AM', '2:00 PM', '8:00 PM']),
  FrequencyOption(label: 'Four Times Daily',    defaultTimes: ['6:00 AM', '12:00 PM', '6:00 PM', '10:00 PM']),
  FrequencyOption(label: 'Every 6 Hours',       defaultTimes: ['6:00 AM', '12:00 PM', '6:00 PM', '12:00 AM']),
  FrequencyOption(label: 'Every 8 Hours',       defaultTimes: ['8:00 AM', '4:00 PM', '12:00 AM']),
  FrequencyOption(label: 'Every 12 Hours',      defaultTimes: ['8:00 AM', '8:00 PM']),
  FrequencyOption(label: 'With Every Meal',     defaultTimes: ['7:30 AM', '1:00 PM', '7:00 PM']),
  FrequencyOption(label: 'Morning',             defaultTimes: ['8:00 AM']),
  FrequencyOption(label: 'Bedtime',             defaultTimes: ['10:00 PM']),
  FrequencyOption(label: 'Once Weekly',         defaultTimes: ['9:00 AM']),
  FrequencyOption(label: 'As Needed (PRN)',     defaultTimes: [], requiresTimes: false),
];

// Form types (shape of medicine)
const List<String> medicineTypes = [
  "Tablet",
  "Capsule",
  "Syrup",
  "Injection",
  "Drops",
  "Spray",
  "Ointment",
  "Cream",
  "Gel",
  "Powder",
  "Inhaler",
  "Patch",
  "Suppository",
  "Mouthwash",
  "Lozenge",
];

// Categories (purpose)
const List<String> medicineCategories = [
  "Antibiotic",
  "Painkiller",
  "Anti-inflammatory",
  "Antipyretic (Fever Reducer)",
  "Antihistamine",
  "Allergy",
  "Vitamin / Supplement",
  "Antacid / Stomach",
  "Cough & Cold",
  "Diabetes",
  "Blood Pressure",
  "Heart",
  "Asthma",
  "Antiviral",
  "Eye / Ear / Nose",
  "Skin / Dermatology",
];
