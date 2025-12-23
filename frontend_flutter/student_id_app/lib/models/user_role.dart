enum UserRole {
  student('Student'),
  merchant('Merchant'),
  admin('Admin');

  final String name;
  const UserRole(this.name);
}