# Patient Region Change Tool

## Overview

This document specifies an admin tool to change a patient's region, handling the complex implications around Stripe billing, care team assignments, and external system updates.

---

## Current State

### Data Model

**Users Table** (`packages/db/models/users.ts`):
```
users
├── regionId (uuid, FK → regions.id)
├── stripePlatformCustomerId (varchar, unique) - Main Outro Stripe account
└── stripePcOrgCustomerId (varchar, unique) - Single PC org Stripe customer
```

**Organizations** (`packages/db/models/organizations.ts`):
```
pcOrgs
├── id (uuid)
├── name (text)
├── stripeAccountId (varchar, unique) - Stripe Connect account ID
└── createdAt (timestamp)

regions
├── id (uuid)
├── name (text)
├── pcOrgId (uuid, FK → pcOrgs.id) - Many regions can share one PC org
├── state (varchar(2), unique) - Two-letter state code
├── activationStatus (enum: testing_only, open_sign_ups, at_capacity)
├── defaultTimeZone (text)
└── insuranceSignupsEnabled (boolean)
```

**Relationship Chain**:
```
User → regionId → Region → pcOrgId → PC Org → stripeAccountId → Stripe Connect Account
```

### How Patients Are Assigned to Regions

1. During onboarding, patient selects their state in the Location step
2. State code is validated against enabled regions
3. On signup completion (`packages/api/workflows/signup.ts`):
   - Region is looked up by state code
   - PC org is fetched via `region.pcOrgId`
   - **Two Stripe customers are created**:
     - Platform customer on main Outro account
     - PC org customer on the connected account via `{ stripeAccount: pcOrg.stripeAccountId }`
   - Both customer IDs are stored on the user record
   - Default clinician is assigned based on region

### Current Limitations

1. **No region change endpoint exists** - `regionId` is set at signup and never updated
2. **Single PC org customer ID** - Users can only have one `stripePcOrgCustomerId` at a time
3. **No history tracking** - If a patient moved regions before, there's no record
4. **Subscriptions are tied to PC org** - Created on the PC org's Stripe Connect account
5. **No outbox event** for region changes - External systems won't be notified

### Current Manual Process (What Ops Does Today)

1. Go to database, find patient by email
2. Look up current `regionId` and `stripePcOrgCustomerId`
3. Determine if new region has different PC org:
   - If same PC org: Just update `regionId` in DB
   - If different PC org:
     a. Go to Stripe dashboard for **new** PC org's connected account
     b. Manually create a new customer with patient's email
     c. Copy the new customer ID
     d. In database transaction:
        - Update `regionId` to new region
        - Update `stripePcOrgCustomerId` to new customer ID
     e. If patient has active subscription:
        - Cancel it in old PC org's Stripe dashboard
        - Manually handle refund/proration
        - Coordinate with patient to re-enroll
4. Update care team assignments manually
5. Update Elation if primary clinician changed
6. No audit trail of the change

**Pain points**:
- Time-consuming (15-30 minutes per patient)
- Error-prone (manual DB updates)
- No audit trail
- Old Stripe customer ID is lost (can't reuse if patient returns)
- Subscription handling is ad-hoc

---

## Target State

### Data Model Changes

**New Junction Table**: `user_pc_org_stripe_customers`
```sql
CREATE TABLE user_pc_org_stripe_customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  pc_org_id UUID NOT NULL REFERENCES pc_orgs(id) ON DELETE CASCADE,
  stripe_customer_id VARCHAR(255) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_active BOOLEAN NOT NULL DEFAULT true,

  UNIQUE(user_id, pc_org_id),
  UNIQUE(stripe_customer_id)
);
```

**Purpose**: Store historical PC org Stripe customer IDs so they can be reused when a patient returns to a region they previously lived in.

**Migration Strategy**:
1. Create new table
2. Migrate existing `stripePcOrgCustomerId` data to new table (derive `pc_org_id` from user's current region)
3. Keep `stripePcOrgCustomerId` on users table as a denormalized "current" pointer for backward compatibility
4. Update all reads to join through the new table
5. Eventually deprecate the direct field

### New Outbox Event

**Event Type**: `USER_REGION_CHANGED`

**Payload**:
```typescript
{
  userId: string
  oldRegionId: string
  newRegionId: string
  oldPcOrgId: string
  newPcOrgId: string
  samePcOrg: boolean
  subscriptionCancelled: boolean
  careTeamReassigned: boolean
  changedBy: string // admin ID
  changedAt: string // ISO timestamp
  notes?: string
}
```

**Targets**: `["elation", "customerio"]`

### Region Change Flows

#### Flow A: Same PC Org Move

When patient moves between regions that share the same PC org (e.g., multiple states under one medical group).

**Steps**:
1. Validate new region exists and is accepting patients
2. Check if patient's insurance is accepted in new region → **warn if not**
3. Update `users.regionId` to new region
4. Reassign care team:
   - Remove care team members not licensed in new region
   - Assign new region's default clinician
5. Update Elation primary physician if changed
6. Create audit log entry
7. Queue `USER_REGION_CHANGED` outbox event

**No Stripe changes needed** - same customer ID works across regions under same PC org.

#### Flow B: Cross PC Org Move

When patient moves to a region under a different PC org.

**Steps**:
1. Validate new region exists and is accepting patients
2. Check if patient's insurance is accepted in new region → **warn if not**
3. Check for existing Stripe customer in new PC org (from junction table)
   - If exists: Reuse it
   - If not: Create new Stripe customer on new PC org's connected account
4. If patient has active subscription:
   - Cancel subscription on old PC org with **prorated refund**
   - Log that patient needs to re-enroll (manual ops follow-up)
5. Update junction table:
   - Set `is_active = false` on old PC org customer record
   - Insert or update new PC org customer record with `is_active = true`
6. Update `users.stripePcOrgCustomerId` to new customer ID
7. Update `users.regionId` to new region
8. Reassign care team (same as Flow A)
9. Update Elation primary physician if changed
10. Create audit log entry
11. Queue `USER_REGION_CHANGED` outbox event

### API Endpoint

**Router**: `packages/api/routers/admin/users/changeRegion.ts`

**Input Schema**:
```typescript
{
  userId: z.string().uuid(),
  newRegionId: z.string().uuid(),
  notes: z.string().optional()
}
```

**Response**:
```typescript
{
  success: boolean
  warnings: string[] // e.g., ["Patient's insurance (Aetna) is not accepted in new region"]
  changes: {
    regionChanged: boolean
    pcOrgChanged: boolean
    subscriptionCancelled: boolean
    refundAmount?: number
    careTeamReassigned: boolean
    newClinicianName?: string
    stripeCustomerCreated: boolean
    stripeCustomerReused: boolean
  }
}
```

**Permissions**: `enforceAdminCan("update", "user")`

**Audit**:
```typescript
auditMiddleware({
  action: "update",
  resource: "user_region",
  extractResourceId: (input) => input.userId,
  description: "Changed patient region"
})
```

### Service Layer

**New Service**: `packages/api/features/region-transfer/regionTransferService.ts`

```typescript
export async function transferPatientRegion(params: {
  userId: string
  newRegionId: string
  adminId: string
  notes?: string
}): Promise<Result<RegionTransferResult, AppErr>>
```

**Responsibilities**:
- Orchestrate the entire flow
- Determine if same-PC-org or cross-PC-org
- Coordinate Stripe, care team, and EHR updates
- Handle rollback on failure
- Return detailed result for UI

### Repository Layer

**New Repository**: `packages/api/features/region-transfer/userPcOrgCustomerRepository.ts`

```typescript
export class UserPcOrgCustomerRepository {
  static async getByUserAndPcOrg(userId: string, pcOrgId: string)
  static async getActiveForUser(userId: string)
  static async getAllForUser(userId: string)
  static async create(data: { userId, pcOrgId, stripeCustomerId })
  static async setActive(userId: string, pcOrgId: string)
  static async deactivateAll(userId: string)
}
```

### UI Components

**Location**: `apps/huxley/src/routes/_home/patients/$userId/user-view/ModalChangeRegion.tsx`

**Features**:
1. Region selector dropdown (filtered to enabled regions)
2. Pre-flight checks displayed:
   - Current region → New region
   - Current PC org → New PC org (or "Same PC org")
   - Insurance compatibility warning (if applicable)
   - Active subscription warning (if applicable, shows refund amount)
   - Care team impact (who will be removed/added)
3. Optional notes field
4. Confirmation button with clear summary of what will happen
5. Success/failure toast with details

**Integration**: Add to Actions dropdown on patient detail page.

### External System Updates

**Elation (EHR)**:
- If primary clinician changes, update via existing Elation integration
- Use outbox event to trigger async update

**CustomerIO**:
- Update patient's region attribute for segmentation
- Triggered via outbox event

**Help Scout**:
- No changes needed (region not stored there)

### Audit Trail

All region changes will be:
1. Logged via `auditMiddleware` to BigQuery
2. Recorded in outbox for event processing
3. Optionally annotated with admin notes

Query for audit: "Show me all region changes for patient X" will be possible via BigQuery or outbox event history.

---

## Edge Cases

### Patient with No Subscription
- Simple case: just update region and care team
- No Stripe subscription operations needed

### Patient with Multiple Subscriptions
- Cancel all subscriptions on old PC org with prorated refunds
- Each gets logged separately

### Patient with Past-Due Subscription
- Still cancel with whatever refund applies
- Note in the result that subscription was past-due

### Patient Already Has Customer in New PC Org
- Happens when patient moved away and is returning
- Reuse the existing customer ID from junction table
- No new Stripe customer creation needed

### Region is at Capacity
- Block the transfer with clear error message
- Admin can override if needed (future enhancement)

### Clinician Licensed in Both Regions
- If current clinician is licensed in new region, keep them
- Only reassign if clinician cannot practice in new region

---

## Success Metrics

1. **Time saved**: Region changes should take < 2 minutes vs 15-30 minutes
2. **Error reduction**: Zero manual DB operations needed
3. **Audit compliance**: 100% of region changes logged
4. **Customer reuse rate**: Track how often we reuse existing Stripe customers

---

## Implementation Phases

### Phase 1: Data Model & Core Service
- Create `user_pc_org_stripe_customers` table
- Migrate existing data
- Build `regionTransferService`
- Build `userPcOrgCustomerRepository`
- Add `USER_REGION_CHANGED` outbox event type

### Phase 2: API & Integration
- Create admin router endpoint
- Wire up Stripe subscription cancellation with prorated refund
- Wire up care team reassignment
- Wire up Elation updates

### Phase 3: UI
- Build `ModalChangeRegion` component
- Add to patient detail Actions menu
- Add pre-flight check display
- Add success/failure feedback

### Phase 4: Polish & Monitoring
- Add metrics/alerting
- Documentation for ops team
- Training materials
