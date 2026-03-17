import { BigInt } from "@graphprotocol/graph-ts"
import {
  RewardEarned,
  CreditsUpdated,
  TierUpdated
} from "../generated/VendRewards/VendRewards"
import { RewardEvent } from "../generated/schema"
import {
  getOrCreateUser,
  getOrCreateGlobalStats,
  makeEventId
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
