class MockData {
  const MockData._();

  static const List<Map<String, dynamic>> onboardingSlides = [
    {
      'title': 'Gas safety at a glance',
      'subtitle': 'Track live cylinder status, valve health, and system conditions instantly.',
      'highlight': '98.7%',
      'caption': 'Gas reserve stable',
    },
    {
      'title': 'Instant risk monitoring',
      'subtitle': 'Catch warnings early with alerts for pressure, battery, and emergency lock events.',
      'highlight': '01:22',
      'caption': 'Last critical check',
    },
    {
      'title': 'Secure control anywhere',
      'subtitle': 'Open or close the valve, schedule a refill, and keep your home protected.',
      'highlight': '24/7',
      'caption': 'Remote visibility',
    },
  ];

  static const List<Map<String, dynamic>> homeStats = [
    {'label': 'Gas level', 'value': '76%', 'trend': '+4.3%', 'tone': 'positive'},
    {'label': 'Battery', 'value': '92%', 'trend': 'Stable', 'tone': 'info'},
    {'label': 'Signal', 'value': '4G', 'trend': 'Strong', 'tone': 'positive'},
    {'label': 'Power', 'value': 'AC', 'trend': 'Online', 'tone': 'positive'},
  ];

  static const List<Map<String, dynamic>> alerts = [
    {
      'title': 'Valve closed due to safety trigger',
      'message': 'Emergency protocol executed automatically by the ESP32 sensor hub.',
      'time': '2 min ago',
      'severity': 'critical',
    },
    {
      'title': 'Gas level is below preferred threshold',
      'message': 'Cylinder health is acceptable but requires refill planning soon.',
      'time': '18 min ago',
      'severity': 'warning',
    },
    {
      'title': 'Battery supply switched to backup',
      'message': 'AC power interruption detected; backup battery is carrying the load.',
      'time': '1 hour ago',
      'severity': 'info',
    },
  ];

  static const List<Map<String, dynamic>> devices = [
    {
      'name': 'Main LPG Controller',
      'model': 'SENZ-ESP32-A1',
      'status': 'Online',
      'detail': 'Zone A • Uptime 99.9%',
      'tone': 'positive',
    },
    {
      'name': 'Valve Actuator',
      'model': 'SV-001',
      'status': 'Closed',
      'detail': 'Safety interlock armed',
      'tone': 'warning',
    },
    {
      'name': 'Sensor Node',
      'model': 'SG-12',
      'status': 'Healthy',
      'detail': 'Pressure and battery normal',
      'tone': 'positive',
    },
  ];

  static const List<Map<String, dynamic>> diagnostics = [
    {'label': 'Gas leak scan', 'value': 'Nominal', 'tone': 'positive'},
    {'label': 'Pressure variance', 'value': '0.8%', 'tone': 'info'},
    {'label': 'Valve response time', 'value': '118 ms', 'tone': 'positive'},
    {'label': 'Battery health', 'value': '92%', 'tone': 'positive'},
    {'label': 'Signal noise', 'value': 'Low', 'tone': 'positive'},
    {'label': 'Safety lock', 'value': 'Armed', 'tone': 'warning'},
  ];

  static const List<Map<String, dynamic>> bookingHistory = [
    {'label': 'Next refill', 'value': '12 Oct', 'detail': 'Cylinder 14.2kg'},
    {'label': 'Priority', 'value': 'Standard', 'detail': 'No emergency restriction'},
    {'label': 'Delivery window', 'value': '10:00-13:00', 'detail': 'Preferred slot'},
  ];
}
