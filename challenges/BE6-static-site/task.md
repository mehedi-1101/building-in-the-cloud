# BE6 — Static Site with CloudFront + API Gateway SQS Integration

## What this challenge covers

- S3 static site hosting (private bucket, modern OAC pattern)
- CloudFront as a CDN in front of S3
- API Gateway with direct SQS integration (no Lambda)
- Connecting a frontend to the BE8 async events pipeline

## What to build

A static webpage hosted on S3 and served through CloudFront. The page has a form where a user can type a message and submit it. The submission goes to API Gateway, which writes it directly to the BE8 SQS queue (`mh-messages`). From there the existing BE8 pipeline takes over — Step Functions routes the message to DynamoDB or SNS based on whether the `type` field is present.

## Full flow

```
User (browser)
  └── CloudFront (CDN, OAC)
        └── S3 (private bucket, static HTML/JS/CSS)
              |
        User fills form, hits Submit
              |
        API Gateway (HTTP API, CORS enabled)
              └── Direct SQS SendMessage integration (no Lambda)
                    └── SQS (mh-messages)   <-- existing BE8 queue
                          └── EventBridge Pipe -> Step Functions -> DynamoDB / SNS
```

## Frontend design decisions

**Input style — structured form fields:**
```
id:     [auto-generated UUID, editable]
type:   [dropdown: order | refund | (leave empty for bad message)]
amount: [number input]
```

The JS assembles these into JSON before submitting. If `type` is left empty, the field is omitted from the JSON — triggers the bad message path.

**User feedback after submission:**
- On submit: show "Message sent. Processing..." with the SQS message ID returned from API Gateway
- Do not show final processing result (DynamoDB or email). That would need a separate GET endpoint and polling — out of scope for BE6.

## Resources to create

- S3 bucket — private, blocks all public access, static site files inside
- CloudFront distribution — S3 origin via OAC, HTTPS only, default cache behaviour
- API Gateway (HTTP API) — POST endpoint with direct SQS SendMessage integration
- API Gateway CORS config — allow CloudFront origin, POST + OPTIONS, Content-Type header
- IAM role for API Gateway — SQS SendMessage permission on `mh-messages` only

## Pass criteria

- Webpage loads via CloudFront HTTPS URL
- Submitting a good message (with type) results in a DynamoDB item
- Submitting a bad message (without type) triggers an SNS email
- S3 bucket is private — direct S3 URL returns AccessDenied
- No Lambda anywhere in the stack

## Important notes

- **Batch processing is fine for single submissions.** The Pipe is configured with batch size 5 and batch window 0, meaning "take up to 5 messages, don't wait." A single submission fires immediately.
- **CORS is on API Gateway, not CloudFront.** Browser blocks cross-origin requests unless API Gateway responds with the right headers.
- **CloudFront caches HTML.** When the static files are updated, CloudFront still serves the old version until cache expires or is manually invalidated.

---

## Open questions

(none right now — add here as they come up during the build)
