# ConnectorHub Overview

**ConnectorHub** is a core component of the Luther Systems platform that enables seamless integration between enterprise systems and the **Common Operations Script** (also known as _phylum_), which automates complex business processes. It acts as a secure, configurable interface between process logic and external systems, allowing the platform to send and receive data across organizational and system boundaries without requiring custom code for each integration.

ConnectorHub listens for events emitted by the Common Operations Script. These events represent requests to external systems—such as verifying a customer’s identity, updating a database, sending an invoice, or triggering a payment. The hub dispatches these requests to the correct third-party service and relays the results back into the business process.

### Key Concepts

- **Event-Driven Process Automation**
  Business processes emit structured events to represent tasks that require interaction with external systems. Each event includes metadata (e.g., system name, organization, payload) and is tagged to a handler that processes the response once it arrives.

- **Connectors**
  A connector is a reusable integration with a third-party system. Examples include Equifax for ID verification, Postgres for database queries, Stripe for payments, and Camunda for workflow execution. The hub uses configuration files to map system names to their corresponding connector and responsible organization.

- **Factories and Handlers**
  When an event is created, it is associated with a business object (e.g., a claim, payment, or task) and a handler that knows how to process the eventual response. These are created using a factory pattern, allowing scalable, stateless processing logic.

- **Response Lifecycle**
  After receiving a response from the external system, the ConnectorHub routes it back into the platform’s logic layer. The platform identifies the original business object and passes the response to the appropriate handler, which may update the object’s state or raise new events.

- **Privacy and Storage**
  Event data can include sensitive or proprietary information. To protect this data, the platform stores event context and payloads in a **private data collection** (PDC) shared only among authorized organizations. The orderer (consistency layer) has no access to this data. Storage strategies are configurable to support privacy, auditability, and data minimization.

### Real-World Example: Insurance Claims Process

Imagine a digital insurance claims process. As a claim progresses, the system must interact with multiple external parties: verifying customer identity, checking policy details, generating and emailing invoices, and issuing payments. ConnectorHub enables this by dispatching requests at each step to the appropriate system and returning the results to the business logic layer.

This enables **end-to-end automation** of processes—without hardcoding integration logic or exposing sensitive data to unnecessary parties.

---

## ConnectorHub Event Functions

These functions generate structured event payloads to be dispatched by **ConnectorHub** to third-party systems. Each function must be used within the context of a connector factory, and returns a `sorted-map` that encapsulates a request for a specific connector.

---

### `mk-email-req`

```elps
(defun mk-email-req (recipient title body)
```

Creates a request to send an email.

#### Arguments

- `recipient` (string): The email address of the recipient.
- `title` (string): The subject line of the email.
- `body` (string): The plain text body of the email.

#### Returns

A `sorted-map` capturing the email request, destined for the connector via the factory and ConnectorHub.

---

### `mk-gocardless-req`

```elps
(defun mk-gocardless-req (details))
```

Creates a request to initiate a GoCardless payment.

#### Arguments

- `details` (sorted-map):

  - `"amount"` (int): Payment amount in minor currency units.
  - `"app_fee"` (int): Application fee amount.
  - `"charge_date"` (string): Date to schedule the charge (ISO 8601).
  - `"currency"` (string): Currency code (e.g., "GBP", "USD").
  - `"faster_ach"` (bool): Whether to enable Faster ACH payment.
  - `"mandate_link"` (string): GoCardless mandate ID.
  - `"metadata"` (sorted-map): Optional key-value metadata.
  - `"reference"` (string): Payment reference label.
  - `"retry_if_possible"` (bool): Whether to retry on failure.

#### Returns

A `sorted-map` capturing the payment request, destined for the connector via the factory and ConnectorHub.

---

### `mk-camunda-start-req`

```elps
(defun mk-camunda-start-req (process_definition_key &optional vars_map))
```

Triggers the start of a Camunda workflow process.

#### Arguments

- `process_definition_key` (string): ID of the process definition to start.
- `vars_map` (sorted-map, optional):

  - `"business_key"` (string): Optional correlation key.
  - Other keys: Additional workflow variables.

#### Returns

A `sorted-map` capturing the workflow start request, destined for the connector via the factory and ConnectorHub.

---

### `mk-camunda-inspect-req`

```elps
(defun mk-camunda-inspect-req (process_instance_id &optional wait_for_state))
```

Inspects the state of a Camunda process instance.

#### Arguments

- `process_instance_id` (string): ID of the workflow instance to inspect.
- `wait_for_state` (string, optional): Optional workflow state to await.

#### Returns

A `sorted-map` capturing the inspection request, destined for the connector via the factory and ConnectorHub.

---

### `mk-equifax-req`

```elps
(defun mk-equifax-req (details))
```

Performs an identity verification request against Equifax.

#### Arguments

- `details` (sorted-map):

  - Required:

    - `"forename"` (string): First name.
    - `"surname"` (string): Last name.
    - `"dob"` (string): Date of birth (YYYY-MM-DD).

  - Optional:

    - `"account_number"` (string)
    - `"account_sort_code"` (string)
    - `"middle_name"` (string)
    - `"address_name"` (string)
    - `"address_number"` (string)
    - `"address_street1"` (string)
    - `"address_street2"` (string)
    - `"address_postcode"` (string)
    - `"address_post_town"` (string)
    - `"previous_address_name"` (string)
    - `"previous_address_number"` (string)
    - `"previous_address_street1"` (string)
    - `"previous_address_street2"` (string)
    - `"previous_address_postcode"` (string)
    - `"previous_address_post_town"` (string)
    - `"nationality"` (string)

#### Returns

A `sorted-map` capturing the identity verification request, destined for the connector via the factory and ConnectorHub.

---

### `mk-psql-req`

```elps
(defun mk-psql-req (query &optional args metadata))
```

Executes a query on a PostgreSQL database.

#### Arguments

- `query` (string): SQL query string.
- `args` (vector of sorted-maps, optional): List of parameters:

  - `"clazz"` (string): Data type class.
  - `"representation"`: Value of the parameter.

- `metadata` (sorted-map, optional): Additional metadata.

#### Returns

A `sorted-map` capturing the database query request, destined for the connector via the factory and ConnectorHub.

---

### `mk-pdfserv-req`

```elps
(defun mk-pdfserv-req (html))
```

Creates a request to convert HTML into a PDF.

#### Arguments

- `html` (string): Raw HTML content to render.

#### Returns

A `sorted-map` capturing the PDF generation request, destined for the connector via the factory and ConnectorHub.

---

### `mk-stripe-charge-req`

```elps
(defun mk-stripe-charge-req (req))
```

Initiates a Stripe charge against a customer.

#### Arguments

- `req` (sorted-map):

  - `"customer_id"` (string): Stripe customer ID.
  - `"amount"` (int): Charge amount in minor units.
  - `"currency"` (string): Currency code.
  - `"source_id"` (string): Payment source (e.g., card token).
  - `"description"` (string): Optional description.

#### Returns

A `sorted-map` capturing the charge request, destined for the connector via the factory and ConnectorHub.

---

### `mk-invoice-ninja-email-req`

```elps
(defun mk-invoice-ninja-email-req (req))
```

Sends an invoice email through Invoice Ninja.

#### Arguments

- `req` (sorted-map):

  - `"invoice_id"` (string): ID of the invoice to email.

#### Returns

A `sorted-map` capturing the email request, destined for the connector via the factory and ConnectorHub.

## Connector Factories

A **connector factory** is a reusable structure that manages business objects (such as claims, payments, or tasks) participating in connector-based workflows. Each object defines how to process events, raise new events, and respond to third-party responses. The factory registers these objects with the platform so that they can be automatically invoked by **ConnectorHub** when responses are received.

Connector factories allow stateful, event-driven process automation where each object represents a unit of business logic with its own lifecycle.

---

### Defining a Connector Factory

A connector factory must provide the following methods:

```elps
(lambda (op &rest args)
  (cond ((equal? op 'name) ...)       ; returns the name of the object type
        ((equal? op 'new) ...)        ; creates a new business object
        ((equal? op 'get) ...)        ; loads an existing object by ID
        ((equal? op 'put) ...)        ; stores a modified object
        ((equal? op 'del) ...)        ; deletes the object by ID
        (:else (error 'unknown op))))
```

Each object created by the factory must itself implement:

```elps
(lambda (op &rest args)
  (cond ((equal? op 'init) ...)       ; initializes the object
        ((equal? op 'handle) ...)     ; processes connector response
        ((equal? op 'data) ...)       ; returns the raw object data
        (:else (error 'unknown op))))
```

---

### Required Factory Operations

| Operation | Description                                               |
| --------- | --------------------------------------------------------- |
| `name`    | Returns the symbolic name of the object (e.g. `"claim"`). |
| `new`     | Creates and returns a new business object.                |
| `get`     | Fetches an existing object by its ID.                     |
| `put`     | Persists an updated object to storage.                    |
| `del`     | Deletes an object from storage.                           |

---

### Required Object Operations

| Operation | Description                                                                                                                                                |
| --------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `init`    | Initializes a new object with default state. Should return a map with at least a `"put"` field containing the object, and optionally an `"events"` vector. |
| `handle`  | Processes a connector response. Can update object state and return new `"put"` and `"events"` data.                                                        |
| `data`    | Returns the current data associated with the object.                                                                                                       |

---

### Example

```elps
(set 'claims (singleton mk-claims))

(register-connector-factory claims)
```

In this example:

- `mk-claims` is a factory that produces and manages `claim` objects.
- Each `claim` object tracks the current state of a claim and raises connector events to external systems.
- `register-connector-factory` makes the factory known to the platform, enabling the phylum to raise events and route responses via ConnectorHub.

---

### Raising Events from the Object

Within the object’s `handle` or `init` methods, events can be created using the helper functions and returned like so:

```elps
(sorted-map
  "put" updated-object
  "events" (vector (mk-email-req "user@example.com" "Hello" "Message")))
```

The returned `"events"` vector is automatically dispatched via ConnectorHub.

---

### Triggering Object Methods

You can invoke object logic manually from within the phylum using the helper functions:

```elps
(defun create-claim ()
  (new-connector-object claims))

(defun trigger-claim (claim-id resp)
  (trigger-connector-object claims claim-id resp))
```

- `create-claim`: Creates and initializes a new claim.
- `trigger-claim`: Processes a connector response for an existing claim object.

## Phylum Unit Testing Example: ConnectorHub Integration

To validate connector workflows in the Luther Platform, we provide unit tests for business objects (e.g., claims) that raise events and process connector responses. This ensures end-to-end correctness of event generation, dispatching, and response handling logic.

A full test suite can be found in the [`claim_test.lisp`](https://github.com/luthersystems/sandbox/blob/main/phylum/claim_test.lisp) file.

### Running the Tests

From the `phylum` directory:

```
cd phylum && make test
```

This invokes `luthersystems/shirotester`, which loads all test files and executes them. The output includes test results and debug logs showing the progression of business object state as it handles connector events.

### Output Example

```
=== RUN   TestFile_claim
=== RUN   TestFile_claim/$load
=== RUN   TestFile_claim/claims
=== RUN   TestFile_claim/test-claim-factory
INFO[...] state=CLAIM_STATE_LOECLAIM_DETAILS_COLLECTED
INFO[...] state=CLAIM_STATE_LOECLAIM_ID_VERIFIED
INFO[...] state=CLAIM_STATE_OOECLAIM_REVIEWED
INFO[...] state=CLAIM_STATE_OOECLAIM_VALIDATED
INFO[...] state=CLAIM_STATE_LOEFIN_INVOICE_ISSUED
INFO[...] state=CLAIM_STATE_OOEFIN_INVOICE_REVIEWED
INFO[...] state=CLAIM_STATE_OOEFIN_INVOICE_APPROVED
INFO[...] state=CLAIM_STATE_OOEPAY_PAYMENT_TRIGGERED
--- PASS: TestFile_claim (0.05s)
```

### Key Test Components

#### 1. **Test Setup**

Overrides the creator function to simulate a fixed organization identity for testing:

```elps
(set 'cc:creator (lambda () "Org1MSP"))
```

#### 2. **Claim Creation and Validation**

```elps
(test "claims"
  (let* ([claim (create-claim)])
    (assert (not (nil? (get claim "state"))))
    (assert (not (nil? (get claim "claim_id"))))
    ...))
```

Creates a new claim object and validates that it has a unique ID and an initialized state.

#### 3. **Populating Claim Data**

```elps
(defun populate-test-claimant! (claim)
  (assoc! claim "claimant" (mk-test-claimant)))
```

Injects test claimant data to simulate a real-world scenario where personal details are required for ID verification.

#### 4. **Event Collection**

```elps
(defun get-connector-event-reqs () ...)
```

Extracts the full list of raised connector events within the current transaction. Useful for inspecting what would be dispatched by ConnectorHub.

#### 5. **Simulating ConnectorHub Response**

```elps
(defun process-single-event-empty-response ()
  (let* ([event-reqs (get-connector-event-reqs)]
         [req (first event-reqs)]
         [req-id (get req "request_id")]
         [resp (sorted-map "request_id" req-id)])
    (connector-handlers 'invoke-handler-with-body resp)))
```

Feeds a mock response into the system to simulate a connector callback. The business object processes the response and transitions state.

#### 6. **Full Event Loop Execution**

```elps
(defun process-event-loop (iters &optional start)
  (when start (start-new-event-loop))
  (if (<= iters 0)
      (assert-no-more-events)
      (progn
        (process-single-event-empty-response)
        (process-event-loop (- iters 1)))))
```

Runs a full process loop: creating a claim, triggering event generation, simulating responses, and asserting the correct number of events at each step.

### Why It Matters

These unit tests:

- Ensure your connector logic emits the correct events
- Confirm your object handlers process responses as expected
- Provide a repeatable testbed for evolving your automation logic
- Let you quickly debug and troubleshoot logic in your Common Operations Script through fast, local unit tests
- Save time by avoiding the need to run the full platform stack during development

### Configuring ConnectorHub Locally

ConnectorHub requires a `fabric/connectorhub.yml` file in your project’s `fabric/` directory to bootstrap its connection to the Fabric network and enable connectors. At a minimum, you must specify the following top-level settings:

```
msp-id: # Your organization’s MSP (Membership Service Provider) identifier (e.g. Org1MSP)
user-id: # Enrollment user for chaincode invocations (e.g. User1). Must match crypto-config data.
org-domain: # Your org’s domain (e.g. org1.luther.systems)
crypto-config-root-path: # Path to Fabric crypto materials (e.g. ./crypto-config) to connect to peer
peer-name: # Name of the peer to connect to (e.g. peer0)
peer-endpoint: # Peer address for gRPC (host:port)
channel-name: # Channel where your chaincode is deployed
chaincode-id: # Chaincode name (e.g. sandbox)
connectors: # Array of connector definitions
  - name: <connector name> # Must match the event “sys” value in your phylum
    mock: <true|false> # Enable mock mode or real integration
    <key>: # Connector-specific section key (filled out below)
      … # (e.g. SMTP settings, URLs, credentials)
```

- **msp-id**: Identifies which MSP will endorse and sign transactions.
- **user-id**: The Fabric identity used for submitting invoke/query calls.
- **org-domain**: Used for constructing TLS/CA endpoints and DNS names.
- **crypto-config-root-path**: Directory containing your crypto materials.
- **peer-name** & **peer-endpoint**: Specify the Fabric peer to target for chaincode operations.
- **channel-name** & **chaincode-id**: Tell ConnectorHub where your business logic lives on the ledger.
- **connectors**: Lists each integration you wish to enable. You’ll declare their detailed settings in separate sections—this placeholder ensures ConnectorHub knows which connectors to initialize.

### Testing ConnectorHub Configuration via Make

Once you’ve defined your `fabric/connectorhub.yml`, you can quickly validate all connector settings without leaving your terminal:

```
cd fabric/
make test-connectors
```

This target launches the ConnectorHub Docker image (read-only mounting your `fabric/` directory), runs:

```
connectorhub test --config-file connectorhub.yaml
```

and prints a status line per connector:

```
  [ OK ] EMAIL
  [ OK ] CAMUNDA_WORKFLOW
  [ OK ] POSTGRES_CLAIMS_DB
  … etc.
```

Any failures will be indicated with `[ ERROR ]` and the Make target will exit non-zero, so you can catch misconfigurations early in your CI or local workflow.

#### AWS SES Connector Settings

Add an entry under `connectors:` in your `fabric/connectorhub.yml`:

```
- name: AWS_SES # Must be exactly “AWS_SES”
  mock: <true|false> # true = built-in mock; false = real AWS SES
  aws_ses:
    region: EU_WEST_2 # One of the SupportedAWSRegion enum values
    from_address: "no-reply@your-domain.com" # Verified SES sender address
    role_arn: "arn:aws:iam::123456789012:role/SESAccessRole"
    access_key_id: "AKIAIOSFODNN7EXAMPLE" # Optional AWS credentials
    secret_access_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" # Optional
```

- **region** must be one of:

  ```
  REGION_UNSPECIFIED, US_EAST_1, US_WEST_2,
  EU_WEST_1, EU_WEST_2, EU_WEST_3,
  EU_CENTRAL_1, AP_SOUTHEAST_1,
  AP_SOUTHEAST_2, AP_NORTHEAST_1
  ```

- **from_address**
  SES-verified “From” email address
- **role_arn**
  IAM Role ARN that ConnectorHub will assume for SES access
- **access_key_id** / **secret_access_key** _(optional)_
  If you prefer direct credential use instead of `role_arn`, supply these AWS keys

For AWS-side setup (verifying the `from_address`, configuring IAM, etc.), see the [SES setup guide](https://dev.luthersystems.com/connectors?connector=awsses&setup=true).

#### Mock Mode Overrides

When `mock: true`, you can inject per-subject errors via `general_settings.mock_settings.mock_responses`:

```
general_settings:
  mock_settings:
    mock_responses:
      "TransientError": # matches any email subject containing this string
        error_message: "simulated SES failure"
```

---

##### Camunda: Workflow Start Connector (`CAMUNDA_WORKFLOW`)

```
- name: CAMUNDA_WORKFLOW # Exactly “CAMUNDA_WORKFLOW”
  mock: <true|false> # true = built-in mock; false = real Camunda REST start
  camunda-start:
    gateway_url: "<URL>" # e.g. "https://camunda.local/engine-rest"
    username: "<string>" # Basic auth username
    password: "<string>" # Basic auth password (sensitive)
    api_token: "<string>" # Optional bearer token (overrides username/password)
```

- **gateway_url**: Base URL for the Camunda “start process” endpoint.
- **username / password / api_token**: HTTP authentication for your Camunda instance.

###### Mock Mode Overrides

When `mock: true`, you can override the default mock response per `processDefinitionKey` via:

```
general_settings:
  mock_settings:
    mock_responses:
      "order-process": # matches any ProcessDefinitionKey containing this string
        processInstanceId: "mock-123"
        bpmnProcessId: "order-process"
        version: 1
        state: "ACTIVE" # ACTIVE, COMPLETED, or CANCELED
        businessKey: "order-999"
        tenantId: "tenant-xyz"
```

Any fields you omit will be filled in by the mock’s default response.

---

##### Camunda: Workflow Inspect Connector (`CAMUNDA_TASKLIST`)

```
- name: CAMUNDA_TASKLIST # Exactly “CAMUNDA_TASKLIST”
  mock: <true|false> # true = built-in mock; false = real Camunda Operate API
  camunda-inspect:
    operate_url: "<URL>" # e.g. "https://camunda.local/operate"
    username: "<string>" # Basic auth username
    password: "<string>" # Basic auth password (sensitive)
    api_token: "<string>" # Optional bearer token (overrides username/password)
```

- **operate_url**: Base URL for the Camunda Operate API.

###### Mock Mode Overrides

When `mock: true`, you can supply per-`processInstanceId` responses via:

```
general_settings:
  mock_settings:
    mock_responses:
      "instance-123": # matches any ProcessInstanceId containing this string
        processInstanceId: "instance-123"
        bpmnProcessId: "order-process"
        version: 2
        state: "COMPLETED" # ACTIVE, COMPLETED, or CANCELED
        businessKey: "order-999"
        tenantId: "tenant-xyz"
        startTime: "2025-06-27T12:00:00Z"
        endTime: "2025-06-27T12:05:00Z"
```

A default mock response is always provided if no key matches, ensuring your tests never block.

#### SMTP Email Connector Settings

Add an entry under `connectors:` in your `fabric/connectorhub.yml`:

```
- name: EMAIL               # Exactly “EMAIL”
  mock: <true|false>        # true = built-in mock; false = real SMTP send
  email:
    smtp_server:   "smtp.sendgrid.net"      # SMTP host (e.g., smtp.sendgrid.net)
    from_address:  "no-reply@your-domain.com" # Sender address for outgoing mail
    port:          587                     # SMTP port (e.g., 587 for TLS, 465 for SSL)
    username:      "apikey"                # SMTP auth username (or API key)
    password:      "<sensitive>"           # SMTP auth password (sensitive)
    use_tls:       true                    # Enable TLS for the connection
```

- **smtp_server**: Hostname of your SMTP provider.
- **from_address**: The “From:” header address (must be allowed by your provider).
- **port**: Port number for SMTP.
- **username / password**: Credentials for SMTP authentication.
- **use_tls**: Toggle STARTTLS/SSL on the connection.

For provider-specific setup (credentials, DNS records, etc.), see the [SMTP Email setup guide](https://dev.luthersystems.com/connectors?connector=email&setup=true).

---

##### Mock Mode Overrides

When `mock: true`, the connector uses an in-memory mock that can:

- **Override** to return an error for matching subjects.

Configure overrides via `general_settings.mock_settings.mock_responses`:

```
general_settings:
  mock_settings:
    mock_responses:
      "Error Subject": # any email Title containing this substring
        error_message: "simulated_email_error"
```

- **Override**: If a Title contains an override key and `error_message` is set, the mock returns that error.

#### Equifax Connector Settings

Add an entry under `connectors:` in your `fabric/connectorhub.yml`:

```
- name: EQUIFAX_ID_VERIFY # Must match exactly “EQUIFAX_ID_VERIFY”
  mock: <true|false> # true = built-in mock; false = real Equifax SOAP API
  equifax:
    aml_url: "https://api.equifax.com/aml"
    full_report_url: "https://api.equifax.com/full-report"
    secrets_manager_key: "projects/myproj/secrets/equifax-api-key"
    region: EU_WEST_2 # AWS region enum, e.g. US_EAST_1, EU_WEST_2, etc.
    logon_url: "https://api.equifax.com/login"
    eidv_url: "https://api.equifax.com/eidv"
```

- **aml_url**: AML (Anti-Money-Laundering) endpoint.
- **full_report_url**: Full credit report API endpoint.
- **secrets_manager_key**: AWS Secrets Manager key holding your Equifax credentials.
- **region**: AWS region where the secret lives.
- **logon_url** / **eidv_url**: SOAP URLs for logon/authentication and EIDV.
- **mock**:

  - `true` → uses the built-in mock implementation
  - `false` → invokes the real Equifax SOAP API (requires proper AWS IAM & secret rotation)

---

##### Built-in Mock Test Users

When `mock: true`, the mock Equifax connector recognizes two predefined test users. Use their exact field values in your requests to simulate different EIDV outcomes:

```
# Built-in Equifax test users (mock mode)
EquifaxTestUsers:
  - name: ConsiderTestUser1 # simulates a PEP result
    account_number: ""
    account_sort_code: ""
    dob: "1945-11-01"
    middle_name: ""
    surname: "Smith"
    forename: "Raymond"
    full_address: "3 High Street"
    address_number: "3"
    address_street1: "High Street"
    address_postcode: "BA13 3BN"
    address_post_town: "Westbury"
    nationality: "GB"

  - name: ClearTestUser2 # simulates EIDV_RESULT_CLEAR
    account_number: "00109396"
    account_sort_code: "110822"
    dob: "1960-01-25"
    middle_name: ""
    surname: "Martin"
    forename: "Luke"
    full_address: "325 Idverifier Street"
    address_number: "325"
    address_street1: "Idverifier Street"
    address_postcode: "CB6 2AG"
    address_post_town: "Ely"
    nationality: "GB"
```

Simply plug one of these into your connector event payload when testing the mock.

---

#### GoCardless Connector Settings

Add an entry under `connectors:` in your `fabric/connectorhub.yml`:

```
- name: GOCARDLESS_PAYMENT # Must match exactly “GOCARDLESS_PAYMENT”
  mock: <true|false> # true = built-in mock; false = real GoCardless API
  gocardless:
    access_token: "sk_test_XXXXXXXXX" # GoCardless API access token
    base_url: "https://api.gocardless.com" # GoCardless endpoint (omit for sandbox)
    webhook_secret: "whsec_XXXXXXXX" # (Optional) secret for webhook validation
```

- **access_token**: your GoCardless API key (test or live).
- **base_url**: the HTTP base URL for GoCardless (e.g. sandbox vs. production).
- **webhook_secret**: used only if you plan to receive & validate GoCardless webhooks.

##### Mock Mode & Overrides

When `mock: true`, the connector uses an in-memory mock rather than calling the real API. It provides:

- A **default** mock response with:

  - `id`: `"123ABC"`
  - `status`: `"submitted"`
  - `amount`/`currency`: taken from your request

- The ability to **override** any field per-reference via `general_settings.mock_settings.mock_responses`:

```
general_settings:
  mock_settings:
    mock_responses:
      "my-ref-001":
        id: "OVERRIDE123"
        amount: 2500 # override amount in minor units
        currency: "EUR" # override currency
        status: "confirmed" # override status
```

- If your payment request’s `reference` matches one of those keys, those values will be used in the mock response.
- All other references fall back to the default.

---

#### Invoice Ninja Connector Settings

Add an entry under `connectors:` in your `fabric/connectorhub.yml`:

```
- name: INVOICE_NINJA # Must be exactly “INVOICE_NINJA”
  mock: <true|false> # true = built-in mock; false = real Invoice Ninja API
  invoice_ninja:
    api_key: "your-api-key" # Your Invoice Ninja API key
    base_url: "https://app.invoiceninja.com" # URL of your Invoice Ninja instance
```

- **api_key**: (sensitive) the API token for authenticating with Invoice Ninja.
- **base_url**: the HTTP base URL for your Invoice Ninja server (cloud or self-hosted).

##### Mock Mode & Overrides

When `mock: true`, a simple in-memory mock is used instead of calling the real API.
You can override the mock response per-invoice via `general_settings.mock_settings.mock_responses`:

```
general_settings:
  mock_settings:
    mock_responses:
      "invoice_123": # key = invoiceId to override
        id: "invoice_123" # must match the key
        status: "override_sent" # new status (defaults to “mock_sent”)
        error_message: "simulated send failure" # optional error message
```

- If your invoice ID matches one of those keys, the mock will return those fields.
- Otherwise it falls back to a **default** response:

  - `id`: `"mock_invoice_id"`
  - `status`: `"mock_sent"`
  - `error_message`: `""`

No other fields are needed.

---

#### Luther PDF Service Connector Settings

Add an entry under `connectors:` in your `fabric/connectorhub.yml`:

```
- name: PDF_INVOICE # Must be exactly “PDF_INVOICE”
  mock: <true|false> # true = built-in mock; false = real PDF service
  pdfserv:
    connection: "http://pdf-service:3000" # gRPC endpoint for the PDF generation service
```

By default, you can run the PDF service via our Docker image:

```
docker run -p 3000:3000 luthersystems/pdfserv
```

Available on Docker Hub: [https://hub.docker.com/r/luthersystems/pdfserv](https://hub.docker.com/r/luthersystems/pdfserv)

##### Mock Mode & Overrides

When `mock: true`, a simple in-memory mock is used. You can override its behavior via `general_settings.mock_settings.mock_responses`:

```
general_settings:
  mock_settings:
    mock_responses:
      "<HtmlBase64_string>":
        pdf_base64: "<override_base64_pdf>" # returned instead of default
        error_message: "<some_error_msg>" # if set, mock returns this error
```

- Each top-level key is the exact `HtmlBase64` value from your `GenerateRequest`.
- If a matching key is found:

  - **error_message** non-empty → mock returns that error
  - otherwise, **pdf_base64** is returned.

- If no key matches, the mock falls back to a default:

  - `pdf_base64`: `"mock_base64_encoded_pdf"`
  - `error_message`: `""`

---

#### Postgres Connector Settings

Add an entry under `connectors:` in your `fabric/connectorhub.yml`:

```
- name: POSTGRES_CLAIMS_DB # Must be exactly “POSTGRES_CLAIMS_DB”
  mock: <true|false> # true = built-in mock; false = real Postgres
  postgres:
    host: "db.example.com" # hostname or IP of your Postgres server
    port: 5432 # port (default: 5432)
    database: "claims_db" # database name
    username: "dbuser" # authentication user
    password: "secret" # authentication password
    ssl_settings:
      POSTGRES_SSL_MODE_VERIFY_FULL
      # one of:
      #   POSTGRES_SSL_MODE_UNSPECIFIED,
      #   POSTGRES_SSL_MODE_DISABLE,
      #   POSTGRES_SSL_MODE_ALLOW,
      #   POSTGRES_SSL_MODE_PREFER,
      #   POSTGRES_SSL_MODE_REQUIRE,
      #   POSTGRES_SSL_MODE_VERIFY_CA,
      #   POSTGRES_SSL_MODE_VERIFY_FULL
```

- **ssl_settings** controls TLS mode (see [PostgreSQL docs](https://www.postgresql.org/docs/current/libpq-ssl.html) for details).
- On the AWS side you may need to configure security groups or certificates for TLS.

##### Mock Mode & Overrides

When `mock: true`, a mock connector simulates query responses. You can pre-seed or override its canned responses via:

```
general_settings:
  mock_settings:
    mock_responses:
      "<SQL query string>":
        columnNames:
          - "id"
          - "name"
        rows:
          - # first row
            - clazz: POSTGRES_CLAZZ_INTEGRAL # enum: POSTGRES_CLAZZ_NULL, _BOOLEAN, _INTEGRAL, _FLOATING_POINT, _TEXT, _BLOB
              representation: "1"
            - clazz: POSTGRES_CLAZZ_TEXT
              representation: "John Doe"
          - # second row (if desired)
            - clazz: POSTGRES_CLAZZ_TEXT
              representation: "foo"
            - clazz: POSTGRES_CLAZZ_TEXT
              representation: "bar"
```

- The **key** is the exact SQL string from your `PostgresRequest.query`.
- **columnNames**: list of column names.
- **rows**: list of rows, each row an ordered list of `{ clazz, representation }` objects.
- If you don’t provide an override for a given query, the mock falls back to:

  - A health-check response for `SELECT 1` → one row, one integral column “1”.
  - No entry for other queries → mock connector will error unless you add one.

_View full connector reference & setup instructions at:_
[https://dev.luthersystems.com/connectors?connector=postgres](https://dev.luthersystems.com/connectors?connector=postgres)

---

#### Stripe Connector Settings

Add an entry under `connectors:` in your `fabric/connectorhub.yml`:

```
- name: STRIPE_PAYMENT # Must be exactly “STRIPE_PAYMENT”
  mock: <true|false> # true = built-in mock; false = real Stripe
  stripe:
    secret: "sk_live_YOUR_SECRET_KEY" # Your Stripe secret key (starts with sk_…)
```

- **secret** is your Stripe API secret key.
- On the Stripe side, ensure that key has permissions for charges and balance retrieval.

##### Mock Mode & Overrides

When `mock: true`, the connector returns canned or overridden responses. You can inject per-customer overrides via `general_settings.mock_settings.mock_responses`:

```
general_settings:
  mock_settings:
    mock_responses:
      "cust_123": # matches StripeRequest.customer_id
        id: "chg_123" # override charge ID
        status: "failed" # override status (e.g. "succeeded", "failed")
        receipt_url: "https://receipt/123"
        # error_message short-circuits: if present, Handle() returns this error
        error_message: "simulated_stripe_error"
      # any other customer IDs here...
```

- **Key**: the exact `customer_id` in your request.
- **id** / **status** / **receipt_url** fill out the `StripeCreateChargeResponse`.
- **error_message** (optional): if non-empty, the mock will return an error instead of a successful response.
- If a customer ID has no entry, a default response is returned:

  ```
  id:         "mock_charge_id"
  status:     "succeeded"
  receipt_url:"https://mock.stripe.com/receipt"
  ```

_For full setup instructions & API reference, see:_
[https://dev.luthersystems.com/connectors?connector=stripe](https://dev.luthersystems.com/connectors?connector=stripe)
