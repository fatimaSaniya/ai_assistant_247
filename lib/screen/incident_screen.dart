import 'package:flutter/material.dart';
import '../database_helper.dart';

class IncidentScreen extends StatefulWidget {
  const IncidentScreen({super.key});

  @override
  State<IncidentScreen> createState() => _IncidentScreenState();
}

class _IncidentScreenState extends State<IncidentScreen> {
  final List<Map<String, dynamic>> _incidents = [];

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    await DatabaseHelper.init();
    final incidents = await DatabaseHelper.getAllKeysAndValues();
    setState(() {
      _incidents.clear();
      _incidents.addAll(incidents);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Incidents"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _incidents.isEmpty
                  ? "No incidents found"
                  : "${_incidents.length} incident${_incidents.length > 1 ? 's' : ''} found",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _incidents.length,
              itemBuilder: (context, index) {
                final incident = _incidents[index];
                final incidentNo = incident['incident_no'] ?? "No Incident Number";
                final incidentTypeName = incident['incident_type_name'] ?? "No Type";

                return ListTile(
                  title: Text(incidentNo),
                  subtitle: Text(incidentTypeName),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(incidentNo),
                        content: Text("Type: $incidentTypeName"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text("Close"),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}