/// Whether a user profile is hidden from discovery and other users.
bool isAccountDeactivated(Map<String, dynamic>? data) {
  return data?['accountDeactivated'] == true;
}
