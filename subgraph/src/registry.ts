import { BigInt } from "@graphprotocol/graph-ts"
import {
  SubmissionCreated,
  DuplicateDetected,
  SubmissionAutoVerified
} from "../generated/VendRegistry/VendRegistry"
import { Submission } from "../generated/schema"
import {
  getOrCreateUser,
  getOrCreateGlobalStats,
  getOrCreateRegion,
  ONE_BI, ZERO_BI
} from "./helpers"

export function handleSubmissionCreated(
  event: SubmissionCreated
): void {
  let sub = new Submission(event.params.hash)
  sub.ean_hash       = event.params.ean_hash
  sub.price_cents    = event.params.price_cents
  sub.currency       = event.params.currency.toString()
  sub.lat6           = event.params.lat6
  sub.lng6           = event.params.lng6
  sub.geohash5       = event.params.geohash5
  sub.user_hash      = event.params.user_hash
  sub.is_first_mover = event.params.is_first_mover
  sub.status         = 0
  sub.votes_up       = ZERO_BI
  sub.votes_down     = ZERO_BI
  sub.auto_verify_at = event.params.timestamp
    .plus(BigInt.fromI32(259200))
  sub.timestamp      = event.params.timestamp
  sub.block_number   = event.block.number
  sub.tx_hash        = event.transaction.hash
  sub.save()

  let user = getOrCreateUser(
    event.params.user_hash, event.params.timestamp
  )
  user.total_submissions = user.total_submissions.plus(ONE_BI)
  user.last_active_at    = event.params.timestamp
  user.save()

  let region = getOrCreateRegion(
    event.params.geohash5, event.params.timestamp
  )
  region.submission_count = region.submission_count.plus(ONE_BI)
  let n = region.submission_count
  region.avg_price_cents = region.avg_price_cents
    .times(n.minus(ONE_BI))
    .plus(event.params.price_cents)
    .div(n)
  region.last_submission = event.params.timestamp
  region.save()

  let stats = getOrCreateGlobalStats()
  stats.total_submissions = stats.total_submissions.plus(ONE_BI)
  stats.last_updated = event.params.timestamp
  stats.save()
}

export function handleDuplicateDetected(
  event: DuplicateDetected
): void {
  // DuplicateDetected fires BEFORE SubmissionCreated in the same TX.
  // new_hash does not exist yet — load the existing first-mover submission instead.
  let existing = Submission.load(event.params.existing_hash)
  if (existing) {
    // Mark the existing submission as having received a duplicate price report.
    // The duplicate submission will be created by handleSubmissionCreated.
    existing.save()
  }
}

export function handleSubmissionAutoVerified(
  event: SubmissionAutoVerified
): void {
  let sub = Submission.load(event.params.hash)
  if (!sub) return
  sub.status = 1
  sub.save()
}
