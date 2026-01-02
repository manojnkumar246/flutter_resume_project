import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'utils.dart';
import 'personal_data_form.dart';

class ResumeListScreen extends StatefulWidget {
  const ResumeListScreen({super.key});
  @override
  State<ResumeListScreen> createState() => _ResumeListScreenState();
}

class _ResumeListScreenState extends State<ResumeListScreen> {
  // Holds the full data from server
  List<dynamic> _allResumes = [];
  // Holds the data currently visible (filtered)
  List<dynamic> _filteredResumes = [];

  bool _isSearching = false;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await http.get(Uri.parse('$kBackendBase/resumes'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _allResumes = data;
          _filteredResumes = data; // Initially, filtered list = all list
        });
      }
    } catch (_) {}
  }

  // Search Logic
  void _runFilter(String enteredKeyword) {
    List<dynamic> results = [];
    if (enteredKeyword.isEmpty) {
      // If the search field is empty, show all users
      results = _allResumes;
    } else {
      // Filter list by name (case insensitive)
      results = _allResumes
          .where((user) => user["name"]
              .toString()
              .toLowerCase()
              .contains(enteredKeyword.toLowerCase()))
          .toList();
    }

    setState(() {
      _filteredResumes = results;
    });
  }

  Future<void> _del(String id) async {
    try {
      final res = await http.delete(Uri.parse('$kBackendBase/resumes/$id'));
      if (res.statusCode == 200) {
        // Reload data to ensure sync with server
        _load();
        // Clear search to avoid confusion or re-run filter
        _searchCtrl.clear();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(
        'Resumes',
        // Replace the default title widget if searching
        customTitle: _isSearching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.black, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Search Name...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                onChanged: (value) => _runFilter(value),
              )
            : null,
        actions: [
          // Search Toggle Button
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  // Closing search: clear text and reset list
                  _isSearching = false;
                  _searchCtrl.clear();
                  _filteredResumes = _allResumes;
                } else {
                  // Opening search
                  _isSearching = true;
                }
              });
            },
          ),
          if (!_isSearching)
            IconButton(icon: const Icon(Icons.refresh), onPressed: _load)
        ],
      ),
      body: Stack(
        children: [
          buildBackground(overlayOpacity: 0.8),
          Column(
            children: [
              // Optional: Show count of results found
              if (_isSearching)
                Container(
                  width: double.infinity,
                  color: Colors.grey[200],
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                  child: Text(
                    "Found ${_filteredResumes.length} result(s)",
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),

              Expanded(
                child: _filteredResumes.isEmpty
                    ? const Center(child: Text("No employees found"))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        // Use filtered list count
                        itemCount: _filteredResumes.length,
                        itemBuilder: (ctx, i) {
                          // Use filtered list item
                          final r = _filteredResumes[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.black)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              title: Text(r['name'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              subtitle: Text('ID: ${r['id']}',
                                  style: const TextStyle(fontSize: 12)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                      icon: const Icon(Icons.visibility),
                                      onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => PersonalDataForm(
                                                  resumeId: r['id'],
                                                  isViewOnly: true)))),
                                  IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      PersonalDataForm(
                                                          resumeId: r['id'])))
                                          .then((_) => _load())),
                                  IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => _del(r['id'])),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
