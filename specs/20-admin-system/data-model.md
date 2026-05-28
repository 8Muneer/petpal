# Data Model: Admin Management System

## 1. Entities

### User (Role Extension)
The existing User entity is extended with administrative fields.
- `role`: `String` (Enum: `owner`, `sitter`, `admin`)
- `isAdmin`: `bool` (Convenience flag, mirrored in custom claims if possible)
- `adminLevel`: `String` (e.g., `SuperAdmin`, `Moderator`)

### Point of Interest (POI)
Managed locations displayed on the Explore and Home screens.
- `id`: `String` (auto-generated)
- `name`: `String`
- `type`: `POIType` (Enum: `park`, `vet`, `store`)
- `latitude`: `double`
- `longitude`: `double`
- `rating`: `double`
- `reviewCount`: `int`
- `imageUrl`: `String`
- `address`: `String`
- `phoneNumber`: `String`
- `isEmergency`: `bool`
- `tags`: `List<String>`
- `createdBy`: `String` (Admin ID)
- `updatedAt`: `DateTime`

### SitterVerificationRequest
Tracks the lifecycle of a sitter's application for the "Verified" badge.
- `id`: `String`
- `userId`: `String` (References `users.id`)
- `status`: `String` (Enum: `pending`, `approved`, `rejected`)
- `documents`: `List<String>` (URLs to IDs, certifications in Storage)
- `notes`: `String` (Admin internal notes)
- `reviewedBy`: `String` (Admin ID)
- `requestedAt`: `DateTime`
- `resolvedAt`: `DateTime`

### ContentReport
Reports from users about inappropriate community content.
- `id`: `String`
- `reporterId`: `String`
- `targetType`: `String` (Enum: `post`, `comment`, `user_profile`)
- `targetId`: `String`
- `reason`: `String`
- `status`: `String` (Enum: `open`, `dismissed`, `resolved`)
- `timestamp`: `DateTime`

## 2. Relationships

- **Admin → POI**: One Admin can manage many POIs.
- **Admin → VerificationRequest**: One Admin reviews many requests.
- **Sitter → VerificationRequest**: One Sitter has one active VerificationRequest at a time.
- **User → ContentReport**: Many Users can report many items.

## 3. Validation Rules

- **POI**: Name and location are mandatory. Rating defaults to 0.0 for new entries.
- **Verification**: Status cannot be changed back to `pending` once `approved`.
- **Admin**: The `admin` role can only be assigned by another existing `admin` or through the Firebase Console.
