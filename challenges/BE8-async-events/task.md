# BE8: Async Communication and Events — Tasks

## Exercise 1: SQS

### Q1 — Batch failure and visibility
An AWS Lambda function is triggered by SQS with a batch size of 5. You send exactly 5 messages to the queue. Lambda successfully processes messages 1, 2, and 3, but throws an unhandled exception while processing message 4.

- How many messages will be visible in the SQS queue after the Lambda execution completes, and why?
- Is there any problem? If yes, how can you solve it?

---

### Q2 — Visibility timeout exceeded
A Lambda function processes SQS messages with a visibility timeout of 30 seconds. A message arrives and Lambda picks it up. Due to a slow external API call, Lambda takes 45 seconds to process the message and then calls `DeleteMessage`.

- What happens to the message?
- Is there a problem?
- How do you fix it?

---

### Q3 — Crash before DeleteMessage
A Lambda consumer reads a message, processes it successfully (writes to DynamoDB), but crashes before calling `DeleteMessage` due to an out-of-memory error.

- What happens next?
- What is the risk?
- How do you design your system to handle this safely?

---

### Q4 — Concurrency and queue draining
Your SQS queue suddenly receives 10,000 messages in 60 seconds. You have a Lambda event source mapping with batch size 10 and maximum concurrency set to 50.

- How many Lambda instances will AWS spin up?
- How many messages will be processed per invocation cycle?
- Approximately how long will it take to drain the queue?
- What happens if you remove the concurrency limit?

---

## Exercise 2: SNS

### Q1 — Retry exhaustion without DLQ
You have an SNS topic with a Lambda subscriber. Lambda fails to process the message 3 times. You have not configured a DLQ on the SNS subscription.

- What happens to the message after retries are exhausted?
- How is a DLQ on an SNS subscription different from a DLQ on an SQS queue?
- Where should the DLQ be configured — on SNS or on SQS?

---

### Q2 — Cross-account subscription
Team A owns an SNS topic in AWS Account 111. Team B wants to subscribe their SQS queue in AWS Account 222 to that topic.

- Is this possible?
- What permissions need to be configured and on which side?
- Who grants access — the SNS topic owner, the SQS queue owner, or both?

---

### Q3 — Fan-out and atomicity
An SNS topic has two subscribers: Lambda A (direct) and SQS Queue B (which Lambda B polls).

An `OrderPlaced` event is published. Lambda A succeeds. Lambda B (via SQS) fails 3 times and the message goes to a DLQ.

- Is the order lost entirely?
- Is Lambda A's work rolled back?
- What does this tell you about SNS fan-out and atomicity?

---

### Q4 — Consumer lag during a flash sale
Your flash sale goes live and your app publishes 50,000 messages per second to an SNS Standard topic. Your SQS subscriber queue receives all messages but your Lambda consumers are processing only 5,000 messages per second.

- Where do messages accumulate?
- Is any message lost?
- What metric do you monitor to detect the backlog?
- How do you scale the consumers?

---

## Exercise 3: Step Functions

### Design a Step Functions Workflow for Media File Processing

Design a workflow using AWS Step Functions to process metadata for uploaded media files.

**Requirements:**

1. A file (ranging from ~1 MB to several GB) is uploaded to an Amazon S3 bucket.
2. The upload event triggers the Step Functions workflow (via Amazon EventBridge).
3. Validate the uploaded file:
   - If the file is not a media file (e.g., PDF), the workflow should fail.
4. If the file is a valid media file:
   - Initiate a virus scan using an external service such as VirusTotal (or any equivalent public tool).
   - Note that the scan may take several minutes, so the workflow must handle long-running asynchronous tasks appropriately.
5. In parallel with the virus scan:
   - Generate media metadata using MediaInfo and output it as JSON.
6. After processing completes:
   - Store the following in an Amazon DynamoDB table:
     - S3 file path
     - Virus scan result/report
     - MediaInfo metadata

---

## Homework

### Message Router: SQS → EventBridge Pipe → Step Functions → DynamoDB / SNS

An SQS queue receives a mix of good and bad JSON messages (all are valid JSON). Build a system that:
- Saves **good** messages to a DynamoDB table
- Sends **bad** messages to an admin email address

**Core Architecture:**
- **Source:** SQS Queue (Primary) + Dead Letter Queue (DLQ)
- **Transport:** EventBridge Pipe with a batch size of 5
- **Processing:** Step Functions
- **Storage:** DynamoDB Table
- **Alerting:** SNS Topic for DLQ notifications

**Constraints:**
- Must handle at least 10 messages at a time (mix of good and bad)
- Must include a way to calculate the total cost of all resources used (individual resource breakdown not required)
- Best solution avoids AWS compute resources (no Lambda/EC2/ECS/EKS) — use native service integrations where possible

**Deliverable:**
IaC (Terraform or CloudFormation) with any necessary compute code (Lambda, EC2, ECS, or EKS if unavoidable). Must be deployable to any AWS account with a few shell commands.
