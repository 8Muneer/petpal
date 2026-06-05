# Data Model: Explore Discovery Hub

## Entities

### 1. SittingService (Browse Sitters View)
| Field | Type | Description |
|-------|------|-------------|
| providerName | String | Displayed as the Title on the card. |
| petTypes | List<String> | Used to generate "Amenities" text (e.g., "Dog Walking"). |
| priceText | String | Bold price on the card (e.g., "₪100"). |
| rating | Double | Displayed in the rating badge. |
| reviewCount | Int | Displayed in parentheses in the rating badge. |
| providerPhotoUrl | String | Main card image background. |

### 2. SittingRequest (Job Discovery View)
| Field | Type | Description |
|-------|------|-------------|
| ownerName | String | Displayed as the Title on the card. |
| petType | PetType | Used to generate "Pet Details" (Breed, Age, Level). |
| budget | String | Bold price on the card. |
| area | String | Location detail. |
| petImageUrl | String | Main card image background. |

## Relationships
- **Pet Owner** → owns → **SittingRequest** (displayed in "My Requests" and Sitter's job feed).
- **Service Provider** → owns → **SittingService** (displayed in Owner's "Browse Sitters" feed).
