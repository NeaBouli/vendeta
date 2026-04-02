import { BigInt } from "@graphprotocol/graph-ts"
import {
  RewardEarned,
  FirstMoverBonusPaid,
  SilentConsensusPaid,
  CreditsUpdated,
  TierUpdated
} from "../generated/VendRewards/VendRewards"
import { RewardEvent } from "../generated/schema"
import {
  getOrCreateUser,
  getOrCreateGlobalStats,
  makeEventId,
  ZERO_BI
} from "./helpers"

export function handleRewardEarned(event: RewardEarned): void {
  let id = makeEventId(event.transaction.hash, event.logIndex)
  let reward = new RewardEvent(id)
  reward.user_hash    = event.params.user_hash
  reward.submission   = event.params.submission_hash
  reward.base_reward  = event.params.base_reward
  reward.final_reward = event.params.final_reward
  reward.reward_type  = event.params.reward_type
  reward.timestamp    = event.block.timestamp
  reward.tx_hash      = event.transaction.hash
  reward.save()

  let user = getOrCreateUser(
    event.params.user_hash, event.block.timestamp
  )
  user.total_credits = user.total_credits
    .plus(event.params.final_reward)
  user.last_active_at = event.block.timestamp
  user.save()

  let stats = getOrCreateGlobalStats()
  stats.total_credits_earned = stats.total_credits_earned
    .plus(event.params.final_reward)
  stats.last_updated = event.block.timestamp
  stats.save()
}

export function handleFirstMoverBonusPaid(
  event: FirstMoverBonusPaid
): void {
  let id = makeEventId(event.transaction.hash, event.logIndex)
  let reward = new RewardEvent(id)
  reward.user_hash    = event.params.user_hash
  reward.submission   = event.params.submission_hash
  reward.base_reward  = ZERO_BI
  reward.final_reward = event.params.bonus_credits
  reward.reward_type  = "FIRST_MOVER_BONUS"
  reward.timestamp    = event.block.timestamp
  reward.tx_hash      = event.transaction.hash
  reward.save()

  let user = getOrCreateUser(
    event.params.user_hash, event.block.timestamp
  )
  user.total_credits = user.total_credits
    .plus(event.params.bonus_credits)
  user.last_active_at = event.block.timestamp
  user.save()

  let stats = getOrCreateGlobalStats()
  stats.total_credits_earned = stats.total_credits_earned
    .plus(event.params.bonus_credits)
  stats.last_updated = event.block.timestamp
  stats.save()
}

export function handleSilentConsensusPaid(
  event: SilentConsensusPaid
): void {
  let id = makeEventId(event.transaction.hash, event.logIndex)
  let reward = new RewardEvent(id)
  reward.user_hash    = event.params.user_hash
  reward.submission   = event.params.submission_hash
  reward.base_reward  = ZERO_BI
  reward.final_reward = event.params.credits_paid
  reward.reward_type  = "SILENT_CONSENSUS"
  reward.timestamp    = event.block.timestamp
  reward.tx_hash      = event.transaction.hash
  reward.save()

  let user = getOrCreateUser(
    event.params.user_hash, event.block.timestamp
  )
  user.total_credits = user.total_credits
    .plus(event.params.credits_paid)
  user.last_active_at = event.block.timestamp
  user.save()

  let stats = getOrCreateGlobalStats()
  stats.total_credits_earned = stats.total_credits_earned
    .plus(event.params.credits_paid)
  stats.last_updated = event.block.timestamp
  stats.save()
}

export function handleCreditsUpdated(
  event: CreditsUpdated
): void {
  let user = getOrCreateUser(
    event.params.user_hash, event.block.timestamp
  )
  user.current_credits = event.params.new_balance
  user.save()
}

export function handleTierUpdated(event: TierUpdated): void {
  let user = getOrCreateUser(
    event.params.user_hash, event.block.timestamp
  )
  user.tier_level = event.params.tier
  user.save()
}
