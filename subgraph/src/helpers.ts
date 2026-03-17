import { BigInt, Bytes } from "@graphprotocol/graph-ts"
import { User, GlobalStats, GeohashRegion } from "../generated/schema"

export const GLOBAL_ID = "global"
export const ZERO_BI   = BigInt.fromI32(0)
export const ONE_BI    = BigInt.fromI32(1)

export function getOrCreateUser(
  user_hash: Bytes,
  timestamp: BigInt
): User {
  let user = User.load(user_hash)
  if (!user) {
    user = new User(user_hash)
    user.trust_score       = 500
    user.tier_level        = 0
    user.total_submissions = ZERO_BI
    user.total_credits     = ZERO_BI
    user.current_credits   = ZERO_BI
    user.total_claimed     = ZERO_BI
    user.last_claim_at     = ZERO_BI
    user.first_seen_at     = timestamp
    user.last_active_at    = timestamp
    user.save()

    let stats = getOrCreateGlobalStats()
    stats.total_users = stats.total_users.plus(ONE_BI)
    stats.last_updated = timestamp
    stats.save()
  }
  return user as User
}

export function getOrCreateGlobalStats(): GlobalStats {
  let stats = GlobalStats.load(GLOBAL_ID)
  if (!stats) {
    stats = new GlobalStats(GLOBAL_ID)
    stats.total_submissions     = ZERO_BI
    stats.total_users           = ZERO_BI
    stats.total_credits_earned  = ZERO_BI
    stats.total_credits_claimed = ZERO_BI
    stats.total_ifr_claimed     = ZERO_BI
    stats.total_votes           = ZERO_BI
    stats.last_updated          = ZERO_BI
    stats.save()
  }
  return stats as GlobalStats
}

export function getOrCreateRegion(
  geohash5: string,
  timestamp: BigInt
): GeohashRegion {
  let region = GeohashRegion.load(geohash5)
  if (!region) {
    region = new GeohashRegion(geohash5)
    region.submission_count = ZERO_BI
    region.avg_price_cents  = ZERO_BI
    region.last_submission  = timestamp
    region.save()
  }
  return region as GeohashRegion
}

export function makeEventId(
  txHash: Bytes,
  logIndex: BigInt
): Bytes {
  return txHash.concatI32(logIndex.toI32())
}
