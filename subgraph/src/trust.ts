import { BigInt } from "@graphprotocol/graph-ts"
import {
  VoteCast,
  ConsensusReached,
  TrustUpdated
} from "../generated/VendTrust/VendTrust"
import { Vote, ConsensusEvent, Submission } from "../generated/schema"
import {
  getOrCreateUser,
  getOrCreateGlobalStats,
  makeEventId,
  ONE_BI
} from "./helpers"

export function handleVoteCast(event: VoteCast): void {
  let voteId = makeEventId(event.transaction.hash, event.logIndex)
  let vote = new Vote(voteId)
  vote.submission    = event.params.submission_hash
  vote.voter_hash    = event.params.voter_hash
  vote.upvote        = event.params.upvote
  vote.voter_trust   = event.params.voter_trust
  vote.weighted_up   = event.params.weighted_up
  vote.weighted_down = event.params.weighted_down
  vote.timestamp     = event.block.timestamp
  vote.tx_hash       = event.transaction.hash
  vote.save()

  let sub = Submission.load(event.params.submission_hash)
  if (sub) {
    sub.votes_up   = event.params.weighted_up
    sub.votes_down = event.params.weighted_down
    sub.save()
  }

  let voter = getOrCreateUser(
    event.params.voter_hash, event.block.timestamp
  )
  voter.last_active_at = event.block.timestamp
  voter.save()

  let stats = getOrCreateGlobalStats()
  stats.total_votes = stats.total_votes.plus(ONE_BI)
  stats.last_updated = event.block.timestamp
  stats.save()
}

export function handleConsensusReached(
  event: ConsensusReached
): void {
  let id = makeEventId(event.transaction.hash, event.logIndex)
  let consensus = new ConsensusEvent(id)
  consensus.submission    = event.params.submission_hash
  consensus.verified      = event.params.verified
  consensus.weighted_up   = event.params.weighted_up
  consensus.weighted_down = event.params.weighted_down
  consensus.timestamp     = event.block.timestamp
  consensus.tx_hash       = event.transaction.hash
  consensus.save()

  let sub = Submission.load(event.params.submission_hash)
  if (sub) {
    sub.status = event.params.verified ? 2 : 3
    sub.save()
  }
}

export function handleTrustUpdated(event: TrustUpdated): void {
  let user = getOrCreateUser(
    event.params.user_hash, event.block.timestamp
  )
  user.trust_score    = event.params.new_trust
  user.last_active_at = event.block.timestamp
  user.save()
}
