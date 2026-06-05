# Data Model: POI Integration

## Entities

### `POI` (Point of Interest)
Represents a physical location like a vet clinic, pet store, or dog park.

| Field | Type | Description | Required |
|-------|------|-------------|----------|
| `id` | String | Unique identifier (Document ID in Firestore) | Yes |
| `name` | String | Name of the location | Yes |
| `type` | String/Enum | Category (e.g., vet, park, store) | Yes |
| `latitude` | Double | Geographic latitude | Yes |
| `longitude` | Double | Geographic longitude | Yes |
| `address` | String | Physical address text | No |
| `phoneNumber` | String | Contact number | No |
| `imageUrl` | String | URL to hero image stored in Firebase Storage | No |
| `isEmergency` | Boolean | True if 24/7 emergency service (mostly for Vets) | Yes |
| `rating` | Double | Average user rating | Yes (Default 0.0) |
| `reviewCount` | Integer | Total number of reviews | Yes (Default 0) |
| `tags` | List<String> | Searchable tags | Yes (Default []) |

## Relationships
- **Admin**: Creates/Edits POIs.
- **User**: Views POIs (Read-only access).

## Database Rules (Firestore)
- `users`: Read access to all verified users.
- `admins`: Read/Write access.
