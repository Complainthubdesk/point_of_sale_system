import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:point_of_sale_system/backend/user_api_service.dart';

class UserProfilePage extends StatefulWidget {
  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _dobController = TextEditingController();
  TextEditingController _joinDateController = TextEditingController();
 UserApiService userApiService = UserApiService(baseUrl:'http://localhost:3000/api');
  String? _username;
  String? _fullName;
  DateTime _dob = DateTime(1990, 1, 1);
  String? _mobileNo;
  String? _email;
  String? _password;
  String? _selectedOutlet;
  DateTime _joinDate = DateTime.now();
  bool _status = true;
  String? _role;
  List<String> outlets = [];
  String? selectedStatus;
  List<dynamic> properties = [];
  List<dynamic> outletConfigurations = [];

  // Simulated list of existing usernames
  List<String> existingUsernames = ["john_doe", "jane_doe", "admin"];
  List<Map<String, dynamic>> users = [];

  void toggleStatus() {
    setState(() {
      _status = (_status == "Active") ? true : false;
    });
  }

  @override
void initState() {
  super.initState();
  _loadDataFromHive();
  fetchUsers();
}


 // Load data from Hive
Future<void> _loadDataFromHive() async {
  var box = await Hive.openBox('appData');
  
  // Retrieve the data
  var properties = box.get('properties');
  var outletConfigurations = box.get('outletConfigurations');
  
  // Check if outletConfigurations is not null
  if (outletConfigurations != null) {
    // Extract the outlet names into the outlets list
    List<String> outletslist = [];
    for (var outlet in outletConfigurations) {
      if (outlet['outlet_name'] != null) {
        outletslist.add(outlet['outlet_name'].toString());
      }
    }

    setState(() {
      this.properties = properties ?? [];
      this.outletConfigurations = outletConfigurations ?? [];
      this.outlets = outletslist; // Set the outlets list
    });
  }
}


  List<Map<String, dynamic>> _parseJson(String jsonString) {
    // You can use a JSON decoder if you save the data in a valid JSON format
    return jsonString.isNotEmpty ? List<Map<String, dynamic>>.from([]) : [];
  }

  Future<void> _selectDate(BuildContext context, bool isDob) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null) {
      setState(() {
        if (isDob) {
          _dob = selectedDate;
          _dobController.text = "${_dob.toLocal()}".split(' ')[0];
        } else {
          _joinDate = selectedDate;
          _joinDateController.text = "${_joinDate.toLocal()}".split(' ')[0];
        }
      });
    }
  }

Future<void> fetchUsers() async {
  try {
    final fetchedUsers = await userApiService.getUsers();
    setState(() {
      users = fetchedUsers;
    });
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error fetching users: $e')),
    );
  }
}

Future<void> saveUserProfile() async {
  if (_formKey.currentState?.validate() ?? false) {
    final newUser = {
      "username": _username,
      "password_hash": _password, // Hash the password in production
      "dob": _dob.toIso8601String(),
      "mobile": _mobileNo,
      "email": _email,
      "outlet": _selectedOutlet,
      "property_id": properties[0]['property_id'], // Add property ID logic if applicable
      "role": _role,
      "status": _status,
      "full_name":_fullName,
      "join_date":_joinDate.toIso8601String()
    };

    try {
      if (users.any((user) => user['username'] == _username)) {
        final userId = users.firstWhere((user) => user['username'] == _username)['user_id'];
        final updatedUser = await userApiService.updateUser(userId.toString(), newUser);
        setState(() {
          final index = users.indexWhere((user) => user['user_id'] == userId);
          users[index] = updatedUser;
        });
      } else {
        final createdUser = await userApiService.addUser(newUser);
        setState(() {
          users.add(createdUser);
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User Profile Saved")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
}

void deleteProfile(int index) async {
  final userId = users[index]['user_id'];
  try {
    await userApiService.deleteUser(userId.toString());
    setState(() {
      users.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User Profile Deleted")));
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error deleting user: $e")));
  }
}




void editProfile(int index) {
  setState(() {
    _username = users[index]['username'];
    _fullName = users[index]['full_name'];
    
    // Parse 'dob' if it's not already a DateTime object
    _dob = users[index]['dob'] is String 
        ? DateTime.parse(users[index]['dob']) 
        : users[index]['dob'];
    
    _mobileNo = users[index]['mobile'];
    _email = users[index]['email'];
    
    // Parse 'join_date' if it's not already a DateTime object
    _joinDate = users[index]['join_date'] is String 
        ? DateTime.parse(users[index]['join_date']) 
        : users[index]['join_date'];
    
    _status = users[index]['status'];
    _selectedOutlet = users[index]['outlet'];
    _role = users[index]['role'];

    // Update text controllers
    _dobController.text = "${_dob.toLocal()}".split(' ')[0];
    _joinDateController.text = "${_joinDate.toLocal()}".split(' ')[0];
  });
}


 

  String? _usernameValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a username';
    }

    // Check if username is unique
    if (existingUsernames.contains(value)) {
      return 'Username already taken. Please choose another one';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("User Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person),
                    ),
                    onChanged: (value) {
                      _username = value;
                    },
                    validator: _usernameValidator,  // Use the username validator here
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    onChanged: (value) {
                      _fullName = value;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _selectDate(context, true),
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: _dobController,
                        decoration: InputDecoration(
                          labelText: 'Date of Birth',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Mobile Number',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    onChanged: (value) {
                      _mobileNo = value;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your mobile number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    onChanged: (value) {
                      _email = value;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedOutlet,
                    onChanged: (newValue) {
                      setState(() {
                        _selectedOutlet = newValue;
                      });
                    },
                    items: outlets.map((outlet) {
                      return DropdownMenuItem<String>( 
                        value: outlet,
                        child: Text(outlet),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      labelText: 'Select Outlet',
                      prefixIcon: Icon(Icons.store),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select an outlet';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    onChanged: (value) {
                      _password = value;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _selectDate(context, false),
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: _joinDateController,
                        decoration: InputDecoration(
                          labelText: 'Join Date',
                          prefixIcon: Icon(Icons.access_time),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _role,
                    onChanged: (newValue) {
                      setState(() {
                        _role = newValue;
                      });
                    },
                    items: ['admin', 'user', 'manager', 'super admin']
                        .map((role) {
                      return DropdownMenuItem<String>(
                        value: role,
                        child: Text(role),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      labelText: 'Role',
                      prefixIcon: Icon(Icons.group),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a role';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: saveUserProfile,
                    child: Text('Save Profile'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            // Display List of Users
            if (users.isNotEmpty)
              ...users.map((user) {
                int index = users.indexOf(user);
                return Card(
                  elevation: 4,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(user['username'] ?? ''),
                    subtitle: Text(user['full_name'] ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => editProfile(index),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => deleteProfile(index),
                        ),
                      ],
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('User Details'),
                            content: Column(mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Username: ${user['username']}'),
                                Text('Full Name: ${user['full_name']}'),
                                Text('Date of Birth: ${_formatDate(user['dob'])}'),
                                Text('Mobile No: ${user['mobile']}'),
                                Text('Email: ${user['email']}'),
                                Text('Join Date: ${ _formatDate(user['join_date'])}'),
                                Text('Status: ${user['status']}'),
                                Text('Role: ${user['role']}'),
                                Text('Outlet: ${user['outlet']}'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text('Close'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
}

String _formatDate(dynamic date) {
  try {
    if (date is String) {
      final parsedDate = DateTime.parse(date).toLocal(); // Convert to local timezone
      return "${parsedDate.day}-${parsedDate.month}-${parsedDate.year}";
    } else if (date is DateTime) {
      return "${date.toLocal().day}-${date.toLocal().month}-${date.toLocal().year}";
    }
  } catch (e) {
    print("Error formatting date: $e");
  }
  return "Invalid Date";
}
