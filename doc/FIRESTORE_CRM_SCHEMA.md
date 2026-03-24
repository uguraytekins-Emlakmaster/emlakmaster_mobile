# CRM Firestore şeması (Rainbow CRM)

Üretim ve geliştirme için ortak alan adları. Koleksiyon adları `AppConstants` ile sabitlenir.

## `users/{userId}`

| Alan | Tip | Not |
|------|-----|-----|
| `name` | string | Görünen ad |
| `role` | string | broker_owner, agent, … |
| `officeId` | string? | Ofis üyeliği |

## `customers/{customerId}`

| Alan | Tip | Not |
|------|-----|-----|
| `fullName` | string | |
| `primaryPhone` | string | |
| `assignedAgentId` | string | Danışman filtresi (`assignedTo` yerine) |
| `email` | string? | |
| `createdAt` | timestamp | Sorgu: `orderBy` ile birlikte index |
| `updatedAt` | timestamp | |
| `lastContactAt` | timestamp? | Oluşturma anında set |
| `source` | string | `uygulama`, `rehber_aramasi`, … |

## `calls/{callId}`

| Alan | Tip | Not |
|------|-----|-----|
| `advisorId` / `agentId` | string | Geriye uyumluluk |
| `customerId` | string? | |
| `createdAt` | timestamp | Liste sırası |
| `durationSec` | int? | |
| `phoneNumber` | string? | |
| `direction` | string | |
| `outcome` | string | `connected`, … |
| `summary` | string? | İsteğe bağlı kısa not |

## `call_summaries/{id}`

AI / Magic Call özeti; `callId`, `customerId`, `assignedAgentId`, `createdAt` ile sorgulanır (mevcut kod).

## `tasks/{taskId}`

| Alan | Tip | Not |
|------|-----|-----|
| `advisorId` | string | Filtre |
| `userId` | string | `advisorId` ile aynı (şema uyumu) |
| `title` | string | |
| `dueAt` / `dueDate` | timestamp | İkisi senkron yazılır |
| `done` / `completed` | bool | İkisi senkron yazılır |
| `customerId` | string? | |
| `createdAt` | timestamp | İlk yazımda `serverTimestamp` |
| `updatedAt` | timestamp | |

## `listings/{listingId}`

| Alan | Tip | Not |
|------|-----|-----|
| `ownerUserId` | string | Manuel eklemede |
| `title`, `price`, `location` | string | |
| `source` | string | `manual`, … |
| `createdAt`, `updatedAt` | timestamp | |

## İndeksler

`firestore.indexes.json`: `customers` — `assignedAgentId` + `createdAt` (desc); `calls` — `advisorId`/`agentId` + `createdAt`; `tasks` — `advisorId` + `dueAt`.
