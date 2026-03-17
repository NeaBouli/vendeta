import { BigInt } from "@graphprotocol/graph-ts"
import {
  ClaimInitiated,
  RateUpdated
} from "../generated/VendClaim/VendClaim"
import { ClaimEvent } from "../generated/schema"
import {
  getOrCreateUser,
  getOrCreateGlobalStats,
  makeEventId
} from "./helpers"

export function handleClaimInitiated(
  event: ClaimInitiated
): void {
  let id = makeEventId(event.transaction.hash, event.logIndex)
  let claim = new ClaimEvent(id)
  claim.user_hash      = event.params.user_hash
  claim.mainnet_wallet = event.params.mainnet_wallet
  claim.credits_burned = event.params.credits_burned
  claim.ifr_amount     = event.params.ifr_amount
  claim.nonce          = event.params.nonce
  claim.timestamp      = event.params.timestamp
  claim.tx_hash        = event.transaction.hash
  claim.save()

  let user = getOrCreateUser(
    event.params.user_hash, event.params.timestamp
  )
  user.total_claimed  = user.total_claimed
    .plus(event.params.credits_burned)
  user.last_claim_at  = event.params.timestamp
  user.last_active_at = event.params.timestamp
  user.save()

  let stats = getOrCreateGlobalStats()
  stats.total_credits_claimed = stats.total_credits_claimed
    .plus(event.params.credits_burned)
  stats.total_ifr_claimed = stats.total_ifr_claimed
    .plus(event.params.ifr_amount)
  stats.last_updated = event.params.timestamp
  stats.save()
}

export function handleRateUpdated(event: RateUpdated): void {
  // Rate change logged via event — no entity needed
}
